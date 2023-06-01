--need decimal(7, 6)
-- I really wish "Use importFromExcel;" worked.
CREATE TABLE [ORD_ElSerag_202208011D].dflt.[Smoking_coefficients_v3] (
	[Col] varchar(50),
	[Never] numeric(10,9),
	[Former] numeric(10,9),
	[Current] numeric(10,9)
)

insert into dflt.Smoking_coefficients_v3 values
('Intercept', -0.039449739, 1.106082966, -1.066633226),
('never_r', 1.553062085, -0.645052233, -0.908009852),
('former_r', -0.085964015, 0.119647905, -0.03368389),
('current_r', -0.416346209, -1.084240753, 1.500586962),
('countTobICD9', -0.194504384, 0.09094934, 0.103555045),
('countTobClin', 0.053469948, -0.016940221, -0.036529727),
('count_u_HealthFac', -0.031266783, 0.034470499, -0.003203716),
('count_q_HealthFac', 0.043742556, -0.028719643, -0.015022913),
('count_w_HealthFac', 0.080165538, 0.001631336, -0.081796875),
('count_f_HealthFac', -0.18254872, 0.248930491, -0.066381771),
('count_c_HealthFac', -0.113791955, 0.034457375, 0.07933458),
('count_s_HealthFac', -0.060486317, 0.067076029, -0.006589712),
('count_n_HealthFac', 0.051071825, 0.009004214, -0.060076039),
('count_chew_Healthfac', -0.49403784, 0.510933875, -0.016896035),
('count_chew_c_Healthfac', -0.243834983, 0.249446617, -0.005611634),
('count_chew_f_Healthfac', 0.166660555, -0.063694318, -0.102966237),
('count_Varenicline', -0.000835689, 0.004044629, -0.00320894),
('count_Nicotine', -0.024421375, 0.007112308, 0.017309067),
('count_Bupropion_HCl', 0.003429339, -0.001494247, -0.001935092),
('count_Nortriptyline', 0.00238192, -0.00095425, -0.00142767),
('count_Clonidine_HCl', 0.001565565, -0.000113497, -0.001452068);
