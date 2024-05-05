import torch
import torch.nn as nn
import torch.nn.functional as F
from ResUNet import ConditionalUnet
from utils import *

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

class ConditionalDDPM(nn.Module):
    def __init__(self, dmconfig):
        super().__init__()
        self.dmconfig = dmconfig
        self.loss_fn = nn.MSELoss()
        self.network = ConditionalUnet(1, self.dmconfig.num_feat, self.dmconfig.num_classes)

    def scheduler(self, t_s):
        beta_1, beta_T, T = self.dmconfig.beta_1, self.dmconfig.beta_T, self.dmconfig.T
        beta_slope = (beta_T - beta_1) / (T-1)
        # ==================================================== #
        # YOUR CODE HERE:
        #   Inputs:
        #       t_s: the input time steps, with shape (B,1). 
        #   Outputs:
        #       one dictionary containing the variance schedule
        #       $\beta_t$ along with other potentially useful constants.       
        beta_t = beta_slope*t_s.to(dtype=torch.float64)
        sqrt_beta_t = torch.sqrt(beta_t, )
        alpha_t = 1 - beta_t
        oneover_sqrt_alpha = 1/torch.sqrt(alpha_t)

        is_scalar = t_s.dim() == 0
        if is_scalar:
            nums = 1 - torch.arange(1, t_s+1)*beta_slope
            alpha_t_bar = torch.prod(nums)
        else:
            alpha_t_bars = []
            for i in range(t_s.shape[0]):
                t_s_i = t_s[i].item() 
                nums = 1 - torch.arange(1, t_s_i+1)*beta_slope
                alpha_t_bars.append(torch.prod(nums))
            alpha_t_bar = torch.stack(alpha_t_bars)

        sqrt_alpha_bar = torch.sqrt(alpha_t_bar)
        sqrt_oneminus_alpha_bar = torch.sqrt(1 - alpha_t_bar)

        # ==================================================== #
        return {
            'beta_t': beta_t,
            'sqrt_beta_t': sqrt_beta_t,
            'alpha_t': alpha_t,
            'sqrt_alpha_bar': sqrt_alpha_bar,
            'oneover_sqrt_alpha': oneover_sqrt_alpha,
            'alpha_t_bar': alpha_t_bar,
            'sqrt_oneminus_alpha_bar': sqrt_oneminus_alpha_bar
        }

    def forward(self, images, conditions):
        T = self.dmconfig.T
        noise_loss = None
        # ==================================================== #
        # YOUR CODE HERE:
        #   Complete the training forward process based on the
        #   given training algorithm.
        #   Inputs:
        #       images: real images from the dataset, with size (B,1,28,28).
        #       conditions: condition labels, with size (B). You should
        #                   convert it to one-hot encoded labels with size (B,10)
        #                   before making it as the input of the denoising network.
        #   Outputs:
        #       noise_loss: loss computed by the self.loss_fn function  .  
        t_samples = torch.randint(low=1, high=T+1, size=(images.shape[0],), device=images.device)
        # conditions = F.one_hot(conditions, num_classes=self.dmconfig.num_classes).to(dtype=torch.float32, device=images.device)
        schedule_params = self.scheduler(t_samples)
        beta_t = schedule_params['beta_t']
        beta_t = beta_t.unsqueeze(1).unsqueeze(2).unsqueeze(3)
        noise = torch.randn_like(images)
        noisy_images = images + torch.sqrt(beta_t) * noise
        
        conditions = F.one_hot(conditions, num_classes=self.dmconfig.num_classes).to(dtype=torch.float32, device=images.device)
        out = self.network(noisy_images, t_samples, conditions)

        noise_loss = self.loss_fn(out, noise)  # Assuming the network predicts the noise that was added

        return noise_loss


        # ==================================================== #
        
        return noise_loss

    def sample(self, conditions, omega):
        T = self.dmconfig.T
        num_channels = self.dmconfig.num_channels
        h, w = self.dmconfig.input_dim
        device = conditions.device

        X_t = None
        # ==================================================== #
        # YOUR CODE HERE:
        #   Complete the training forward process based on the
        #   given sampling algorithm.
        #   Inputs:
        #       conditions: condition labels, with size (B). You should
        #                   convert it to one-hot encoded labels with size (B,10)
        #                   before making it as the input of the denoising network.
        #       omega: conditional guidance weight.
        #   Outputs:
        #       generated_images  
        X_t = torch.randn(conditions.shape[0], num_channels, h, w).to(dtype=torch.float32, device=device)
        # conditions = F.one_hot(conditions, num_classes=self.dmconfig.num_classes).to(dtype=torch.float32, device=device)
        cond_mask = torch.full(conditions.size(), -1).to(dtype=torch.float32, device=device)

        with torch.no_grad():
            for t in range(T, 0, -1):
                if t > 1: z = torch.randn((num_channels, h, w)).to(dtype=torch.float32, device=device)
                else: z = torch.zeros((num_channels, h, w)).to(dtype=torch.float32, device=device) 
                t_arr = torch.full((conditions.shape[0], 1), t).view(-1, 1, 1, 1).to(dtype=torch.float32, device=device)
                undo_noise = (1 + omega) * self.network(X_t, t_arr, conditions) - omega * self.network(X_t, t_arr, cond_mask)

                scheduler_t = self.scheduler(torch.full((conditions.shape[0], 1), t))
                oneover_sqrt_alpha = scheduler_t["oneover_sqrt_alpha"].view(-1, 1, 1, 1).to(dtype=torch.float32, device=device)
                print(oneover_sqrt_alpha, "HERE")
                oneminus_alpha_t = 1 - scheduler_t["alpha_t"].view(-1, 1, 1, 1).to(dtype=torch.float32, device=device)
                sqrt_oneminus_alpha_bar = scheduler_t["sqrt_oneminus_alpha_bar"].view(-1, 1, 1, 1).to(dtype=torch.float32, device=device)
                sqrt_beta_t = scheduler_t["sqrt_beta_t"].view(-1, 1, 1, 1).to(dtype=torch.float32, device=device)
                X_t = oneover_sqrt_alpha * (X_t - oneminus_alpha_t / sqrt_oneminus_alpha_bar * undo_noise) + sqrt_beta_t * z

        # ==================================================== #
        
        generated_images = (X_t * 0.3081 + 0.1307).clamp(0,1) # denormalize the output images
        return generated_images