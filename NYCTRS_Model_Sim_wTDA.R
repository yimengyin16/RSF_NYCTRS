# This script conducts the simulation of the finance of NYCTRS


run_sim <- function(tier_select_,
                    AggLiab_,
                    #PR.Tiers_ = PR.Tiers,
                    #DC.Tiers_ = DC.Tiers,
                    i.r_ = i.r,
                    #i.r_geoReturn_ = i.r_geoReturn,
                    init_amort_raw_ = init_amort_raw, # amount.annual, year.remaining 
                    init_unrecReturns.unadj_ = init_unrecReturns.unadj,
                    paramlist_ = paramlist,
                    Global_paramlist_ = Global_paramlist){

  # Run the section below when developing new features.
      # tier_select_ =  "t4a" #  Tier_select
      # i.r_ = i.r
      # #i.r_geoReturn_ = i.r_geoReturn
      # AggLiab_        = AggLiab
      # #PR.Tiers_ = PR.Tiers
      # init_amort_raw_ = init_amort_raw
      # init_unrecReturns.unadj_ = init_unrecReturns.unadj
      # paramlist_      = paramlist
      # Global_paramlist_ = Global_paramlist
  
     # Tier_select_ =  "sumTiers" #  Tier_select
     # i.r_ = i.r
     # PR.Tiers_ = PR.Tiers
     # AggLiab_        = AggLiab.sumTiers
     # i.r_geoReturn_ = i.r_geoReturn
     # init_amort_raw_ = init_amort_raw
     # init_unrecReturns.unadj_ = init_unrecReturns.unadj
     # paramlist_      = paramlist
     # Global_paramlist_ = Global_paramlist
  

  assign_parmsList(Global_paramlist_, envir = environment())
  assign_parmsList(paramlist_,        envir = environment())
  
  # if(Tier_select_ != "sumTiers") init_amort_raw_ %<>% filter(tier == Tier_select_) 

  # if(Tier_select_ != "sumTiers"){
  #   if(!DC_reform) EEC_rate <- tier.param[Tier_select_, "EEC_rate"]
  #   if(DC_reform)  EEC_rate <- tier.param[Tier_select_, "ScnDC_EEC_DB.rate"]
  # } 
  # 
  # if(Tier_select_ == "sumTiers"){
  #   
  #   if(!DC_reform){
  #   EEC_baseRate_tCD <- tier.param["tCD", "EEC_rate"]
  #   EEC_baseRate_tE  <- tier.param["tE", "EEC_rate"]
  #   EEC_baseRate_tF  <- tier.param["tF", "EEC_rate"]
  #   }
  #   
  #   if(DC_reform){
  #     EEC_baseRate_tCD <- tier.param["tCD", "ScnDC_EEC_DB.rate"]
  #     EEC_baseRate_tE  <- tier.param["tE",  "ScnDC_EEC_DB.rate"]
  #     EEC_baseRate_tF  <- tier.param["tF",  "ScnDC_EEC_DB.rate"]
  #   }
  #   
  # } 
  
  # if(Tier_select_ != "sumTiers") EEC_rate <- tier.param[Tier_select_, "EEC_rate"]
  # 
  # if(Tier_select_ == "sumTiers"){
  #   
  #   EEC_baseRate_tCD <- tier.param["tCD", "EEC_rate"]
  #   EEC_baseRate_tE  <- tier.param["tE", "EEC_rate"]
  #   EEC_baseRate_tF  <- tier.param["tF", "EEC_rate"]
  #   
  # } 
  
  
  #*************************************************************************************************************
  #                                     Defining variables in simulation ####
  #*************************************************************************************************************  
  
  # Now we do the actuarial valuations 
  # In each period, following values will be caculated:
  # AL: Total Actuarial liability, which includes liabilities for active workers and pensioners.
  # NC: Normal Cost  
  # MA: Market value of assets.
  # AA: Actuarial value of assets.
  # EAA:Expected actuarial value of assets.
  # UAAL: Unfunded accrued actuarial liability, defined as AL - NC
  # EUAAL:Expected UAAL.
  # PR: payroll 
  # LG: Loss/Gain, total loss(positive) or gain(negative), Caculated as LG(t+1) = (UAAL(t) + NC(t))(1+i) - C - Ic - UAAL(t+1), 
  # AM: Amount to be amortized at period t. 
  # i is assumed interest rate. ELs of each period will be amortized seperately.  
  # SC: Supplement cost 
  # ADC: actuarially required contribution by employer. NC + SC - EEC
  # C : Actual contribution
  # C_ADC: shortfall in paying ADC
  # B : Total beneift Payment   
  # Ic: Assumed interest from contribution, equal to i*C if C is made at the beginning of time period. i.r is real rate of return. 
  # Ia: Assumed interest from AA, equal to i*AA if the entire asset is investible. 
  # Ib: Assumed interest loss due to benefit payment, equal to i*B if the payment is made at the beginning of period
  # I.r : Total ACTUAL interet gain, I = i.r*(AA + C - B), if AA is all investible, C and B are made at the beginning of period.
  # Funded Ratio: AA / AL
  # C_PR: contribution as % of payroll
  
  # Formulas
  # AL(t), NC(t), B(t) at each period are calculated using the workforce matrix and the liability matrix.
  # MA(t+1) = AA(t) + I(t) + C(t) - B(t), AA(1) is given
  # EAA(t+1)= AA(t) + EI(t)
  # AA(t+1) = (1-w)*EAA(t+1) + w*MA(t+1)
  # I.r(t) = i.r(t)*[AA(t) + C(t) - B(t)]
  # Ia(t) = i * AA(t)
  # Ib(t) = i * B(t)
  # Ic(t) = i * C(t)
  # EI(t) = Ia(t) - Ib(t) + Ic(t)
  # ADC   = NC(t) + SC(t)
  # ADC.ER = NC(t) + SC(t) - EEC(t)
  # C(t) = NC(t) + SC(t)
  # UAAL(t) = AL(t) - AA(t)
  # EUAAL(t) = [UAAL(t-1) + NC(t-1)](1+i(t-1)) - C(t-1) - Ic(t-1)
  # LG(t) =   UAAL(t) - EUAAL for t>=2 ; LG(1) = -UAAL(1) (LG(1) may be incorrect, need to check)
  # More on LG(t): When LG(t) is calculated, the value will be amortized thourgh m years. This stream of amortized values(a m vector) will be 
  # placed in SC_amort[t, t + m - 1]
  # SC = sum(SC_amort[,t])
  # ExF = B(j) - C(j)
  
  # About gains and losses
  # In this program, the only source of gain or loss is the difference between assumed interest rate i and real rate of return i.r,
  # which will make I(t) != Ia(t) + Ic(t) - Ib(t)
  
  
  
  # Set up data frame
  penSim0 <- data.frame(year = init_year:(init_year + nyear - 1)) %>%
    mutate(AL   = 0, #
           MA   = 0, #
           AA   = 0, #
           EAA  = 0, #
           FR   = 0, #
           ExF  = 0, # 
           UAAL = 0, #
           EUAAL= 0, #
           LG   = 0, #
           Amort_basis  = 0, # amount to be amortized: AM(t) = LG(t) + [ADC(t - 1) - C(t-1)]*[1 + i(t-1)], i.e. actuarial loss/gain plus shortfall in paying NC+SC in last period(plus interests) 
           # Switch_amort = 0, 
           NC   = 0, #
           SC   = 0, #
           EEC  = 0, #
           ERC  = 0, #
           ADC  = 0, #
           ADC.ER = 0, #
           C    = 0, #
           C_ADC= 0, #
           B    = 0, #                        
           I.r  = 0, #                        
           I.e  = 0, #
           I.dif= 0,
           Ia   = 0, #                         
           Ib   = 0, #                         
           Ic   = 0, #  
           i    = i,
           i.r  = 0,
           PR   = 0,
           ADC_PR = 0,
           C_PR = 0,
           nactives  = 0,
           nretirees = 0,
           nterms    = 0,
    			 
    			 # OYLM
    			 ADC_current = 0,
    			 ADC.ER_current = 0,
    			 ADC_lag = 0,
    			 ADC.ER_lag = 0,
    			 
    			 
    			 # TDA variables
    			 MA.TDA = 0,     # TDA assets
    			 I.TDA.fixed  = 0, # fixed TDA return
    			 I.TDA.actual = 0, # actual TDA return
    			 I.dif.TDA    = 0, # investment losses/gains due to TDA
    			 i.r.wTDA     = 0 # effective QPP investment returns after accounting for TDA
    			    			 )
  # penSim0 <- as.list(penSim0)
  
  
  
  # Vector used in asset smoothing
  # s.vector <- seq(0,1,length = s.year + 1)[-(s.year+1)]; s.vector  # a vector containing the porportion of 
  #s.vector.TDA <- seq(0,1,length = s.year.TDA + 1)[-(s.year.TDA+1)]; s.vector.TDA  # a vector containing the porportion of 
  # s.vector <- c(0, 0.15, 0.3, 0.45, 0.6, 0.8)
  s.vector <- c(0, 0.2, 0.4, 0.55, 0.7, 0.85)
  
  s.vector.TDA <- s.vector
  #*************************************************************************************************************
  #                                 Defining variables in simulation  ####
  #*************************************************************************************************************
  
  # # For PSERS
  # if(Tier_select_ == "sumTiers"){
  #   penSim0$PR_tCD <- PR.Tiers_[, "PR_tCD"]
  #   penSim0$PR_tE <-  PR.Tiers_[, "PR_tE"]
  #   penSim0$PR_tF <-  PR.Tiers_[, "PR_tF"]
  #   
  #   penSim0$EEC.totRate_tCD <- tier.param["tCD", "EEC_rate"]
  #   penSim0$EEC.totRate_tE  <- tier.param["tE",  "EEC_rate"]
  #   penSim0$EEC.totRate_tF  <- tier.param["tF",  "EEC_rate"]
  #   
  #   penSim0$EEC_tCD <- rep(0, nyear)
  #   penSim0$EEC_tE  <- rep(0, nyear)
  #   penSim0$EEC_tF  <- rep(0, nyear)
  #   
  #   penSim0$sharedRisk.rate <- rep(0, nyear)
  #   
  #   penSim0$SharedRiskEval <- ((seq_len(nyear) + init_year - 1) - 2016) %% 3 == 0  # TRUE in the year to determine if the EEC rate should be changed
  # 
  #   penSim0$i.r_geoReturn <- rep(0, nyear) # placeholder 
  #   
  #   penSim0$ERC.final <- rep(0, nyear)
  #   
  #   
  #   
  #   penSim0$DC_EEC_tCD <-  DC.Tiers_[, "DC_EEC_tCD"]
  #   penSim0$DC_EEC_tE  <-  DC.Tiers_[, "DC_EEC_tE"]
  #   penSim0$DC_EEC_tF  <-  DC.Tiers_[, "DC_EEC_tF"]
  #   
  #   penSim0$DC_ERC_tCD <-  DC.Tiers_[, "DC_ERC_tCD"]
  #   penSim0$DC_ERC_tE  <-  DC.Tiers_[, "DC_ERC_tE"]
  #   penSim0$DC_ERC_tF  <-  DC.Tiers_[, "DC_ERC_tF"]
  #       
  # }
  
  
  
  
  
  
  # AL(j)
  penSim0$AL.act.laca   <- AggLiab_$active[, "ALx.laca.yearsum"]
  penSim0$AL.act.v      <- AggLiab_$active[, "ALx.v.yearsum"]
  penSim0$AL.act.death   <- AggLiab_$active[, "ALx.death.yearsum"]
  penSim0$AL.act.disbRet <- AggLiab_$active[, "ALx.disbRet.yearsum"]
  penSim0$AL.act         <-  with(penSim0, AL.act.laca + AL.act.v + penSim0$AL.act.disbRet + penSim0$AL.act.death)
  
  penSim0$AL.la    <- AggLiab_$la[,   "ALx.la.yearsum"]
  #penSim0$AL.ca    <- AggLiab_$ca[,   "liab.ca.yearsum"]
  penSim0$AL.term  <- AggLiab_$term[, "ALx.v.yearsum"]
  penSim0$AL.death <- AggLiab_$death[,"ALx.death.yearsum"]
  penSim0$AL.disbRet  <- AggLiab_$disbRet[, "ALx.disbRet.yearsum"]
  
  penSim0$AL       <- with(penSim0, AL.act + AL.la + AL.term + AL.disbRet + AL.death)
  
  
  # NC(j)
  penSim0$NC.laca <- AggLiab_$active[, "NCx.laca.yearsum"]
  penSim0$NC.v    <- AggLiab_$active[, "NCx.v.yearsum"]
  penSim0$NC.death<- AggLiab_$active[, "NCx.death.yearsum"]
  penSim0$NC.disbRet <- AggLiab_$active[, "NCx.disbRet.yearsum"] 
  penSim0$NC      <-  with(penSim0, NC.laca + NC.v + NC.disbRet + NC.death)
  
  
  # PVFB(j)
  penSim0$PVFB.laca <- AggLiab_$active[, "PVFBx.laca.yearsum"]
  penSim0$PVFB.v    <- AggLiab_$active[, "PVFBx.v.yearsum"]
  penSim0$PVFB.death<- AggLiab_$active[, "PVFBx.death.yearsum"]
  penSim0$PVFB.disbRet <- AggLiab_$active[, "PVFBx.disbRet.yearsum"] 
  penSim0$PVFB         <-  with(penSim0, PVFB.laca + PVFB.v + PVFB.disbRet + PVFB.death) #Note this is the total PVFB for actives. PVFB for retirees/beneficiaries are the same as AL.
  
  
  # PVFNC(j)
  penSim0$PVFNC.laca    <- AggLiab_$active[, "PVFNC.laca.yearsum"]
  penSim0$PVFNC.v       <- AggLiab_$active[, "PVFNC.v.yearsum"]
  penSim0$PVFNC.death   <- AggLiab_$active[, "PVFNC.death.yearsum"]
  penSim0$PVFNC.disbRet <- AggLiab_$active[, "PVFNC.disbRet.yearsum"] 
  penSim0$PVFNC         <-  with(penSim0, PVFNC.laca + PVFNC.v + PVFNC.disbRet + PVFNC.death)
  
  # B(j)
  penSim0$B.la    <- AggLiab_$la[, "B.la.yearsum"]
  # penSim0$B.ca    <- AggLiab_$ca[, "B.ca.yearsum"]
  penSim0$B.v     <- AggLiab_$term[, "B.v.yearsum"]
  penSim0$B.death <- AggLiab_$death[, "B.death.yearsum"]
  penSim0$B.disbRet  <- AggLiab_$disbRet[, "B.disbRet.yearsum"]
  penSim0$B       <- with(penSim0, B.la + B.v + B.disbRet + B.death) 
  
  # PR(j)
  penSim0$PR <- AggLiab_$active[, "PR.yearsum"]
  
  # EEC(j)
  penSim0$EEC <- AggLiab_$active[, "EEC.yearsum"]
  
  # PVFEEC(j)
  penSim0$PVFEEC <- AggLiab_$active[, "PVFEEC.yearsum"]

  
  # PVFS(j)
  penSim0$PVFS <- AggLiab_$active[, "PVFSx.yearsum"]
  
  
  # nactives, nretirees, nterms
  penSim0$nactives  <- AggLiab_$active[, "nactives"]
  penSim0$nla       <- AggLiab_$la[, "nla"]
  #penSim0$n.ca.R1   <- AggLiab_$ca[, "n.R1"]
  #penSim0$n.ca.R0S1 <- AggLiab_$ca[, "n.R0S1"]
  penSim0$nterms    <- AggLiab_$term[, "nterms"]
  penSim0$ndeathBen <- AggLiab_$death[, "ndeathBen"]
  penSim0$ndisbRet   <- AggLiab_$disbRet[,  "ndisbRet"]
  #penSim0$ndisb.ca.R0S1 <- AggLiab_$disb.ca[,  "n.disb.R0S1"]

  
 
  #*************************************************************************************************************
  #                                 Calculating NC under One-Year-Lag-Method ####
  #*************************************************************************************************************  
  # 
  # penSim0 %>% select(year, NC, EEC, PVFNC, PVFEEC, PVFS, PR) %>% 
  # 	mutate(PVFNC_ER = PVFNC - PVFEEC,
  # 				 NC_PR_indiv = NC / PR,
  # 				 NC_PR_agg   = PVFNC / PVFS)
  # 
  # 
  
  
  	
  	
  penSim0 <- as.list(penSim0) # Faster to extract elements from lists than frame data frames.
  
  
  penSim0 %>% as.data.frame
  
  
  
  
  #*************************************************************************************************************
  #                                  Setting up initial amortization payments ####
  #*************************************************************************************************************  
  
  # Matrix representation of amortization of amort payment schedule: better visualization but larger size
   # Rows:    schedule of amortization payments for losses/gains occurred in a certain year. 
   # Columns: each column contains all the amortization payments that need to be paid in a simulation year. 
   #          Column i corresponds to year i. 
   #          Column sums give the total amortization payments. 
    
  m.max <- max(init_amort_raw_$year.remaining, m)       # max number of rows and columns needed
  SC_amort0 <- matrix(0, nyear + m.max, nyear + m.max)
  # SC_amort0
  
  
  # Amortization payment amounts for losses/gains occured piror to year 1 (from plan docs). Set up the matrix. 
  SC_amort.init <- matrix(0, nrow(init_amort_raw_), nyear + m.max)
 
   
  # Adjustment factor for initial amortization payments 
      # Factor is defined as the initial model UAAL as a proportion of UAAL in AV.
      # WARNING: Does not work with "method 2" for AA.

   MA.year1.model <- switch(init_MA_type, 
   									    MA = MA_0,                         # Use preset value
   									    AL = penSim0$AL[1],                # Assume inital fund equals inital liability.
   									    AL_pct = penSim0$AL[1] * MA_0_pct) # Inital MA is a proportion of inital AL
   
   AA.year1.model  <-
   	ifelse(init_AA_type == "AL_pct",
   				 penSim0$AL[1] * AA_0_pct,         # Initial AA as a % of initial AL
   				 ifelse(init_AA_type == "AA0", AA_0,    # preset value of AA
   				 			 with(penSim0, MA.year1.model))    # Assume inital AA equals inital liability.
   )
   
   AL.year1.model   <- penSim0$AL[1]
   
   UAAL.year1.model <- AL.year1.model - AA.year1.model
   
   factor.initAmort <- UAAL.year1.model/ 28249467000 # AV2016lag page n14, sum of outstanding amortization basis
   # Notes: Theoretically, the AV UAAL should be equal to the sum of outstanding amortization balance. Need to check the document
   
   if(useAVamort){
   	SC_amort.init.list <- mapply(amort_LG, 
   															 p = init_amort_raw_$balance * factor.initAmort , 
   															 m = init_amort_raw_$year.remaining, 
   															 method = init_amort_raw_$amort.method,
   															 skipY1 = init_amort_raw_$skipY1,
   															 MoreArgs = list(i = i, g = salgrowth_amort, end = FALSE), SIMPLIFY = F)
   	
   	for(j in 1:nrow(SC_amort.init)){
   		SC_amort.init[j, 1:init_amort_raw_$year.remaining[j]] <- SC_amort.init.list[[j]]
   	}
   }
   
  # SC_amort.init
   
   
  nrow.initAmort <- nrow(SC_amort.init)

  SC_amort0 <- rbind(SC_amort.init, SC_amort0)
  # Notes:
  #   The amortization basis of year j should be placed in row nrow.initAmort + j - 1. 
  #   This creates the issue for year 1 that whether we should use the amortization from the document or that calculated from the model
  #   Need to think this through. 
  #   For sim -1, which is for check model consistency, all amort payments for past gains/losses are set to 0. 
  
  # # save(SC_amort0, file = "SC_amort0.RData")  
  
  #*************************************************************************************************************
  #                                  Setting up TDA  ####
  #*************************************************************************************************************  
  
  penSim0$MA.TDA[1] <- switch(init_MA_TDA_type,
  														MA_pct = MA.year1.model * init_MA_TDA_pct,
  														preset = init_MA_TDA_preset)
  
  
  
  
  
  #*************************************************************************************************************
  #                                       Simuation  ####
  #*************************************************************************************************************
    
  cl <- makeCluster(ncore) 
  registerDoParallel(cl)
  
  
  penSim_results <- foreach(k = -1:nsim, .packages = c("dplyr", "tidyr")) %dopar% {
    # k <- 0
    # initialize
    penSim   <- penSim0
    SC_amort <- SC_amort0
    
    if(k == -1) SC_amort[,] <- 0
    
    penSim[["i.r"]] <- i.r_[, as.character(k)]
    # penSim[["i.r_geoReturn"]] <- i.r_geoReturn_[, as.character(k)]
    
    
    source("Functions.R")
    
    for (j in 1:nyear){
        
        # j <- 5
        # j <- 2
      
    	#***********************************
      #   1. MA(j), AA(j) and UAAL(j)   **
      #***********************************
    	
    	# Year 1
    	if(j == 1) {penSim$MA[j]  <- ifelse(k == -1, penSim$AL[j],                   # k = -1 is for testing model consistency
                                          switch(init_MA_type, 
                                                 MA0 = MA_0,                       # Use preset value
                                                 AL  = penSim$AL[j],               # Assume inital fund equals inital liability.
                                                 AL_pct = penSim$AL[j] * MA_0_pct) # Inital MA is a proportion of inital AL
                                          )
    	
                 penSim$AA[j]  <- ifelse(init_AA_type == "AL_pct" & k != -1, penSim$AL[j] * AA_0_pct,  # Inital MA is a proportion of inital AL;  
                                             ifelse(init_AA_type == "AA0" & k != -1, AA_0,             # Use preset value 
                                                    switch(smooth_method,
                                                           method1 =  with(penSim, MA[j]),             # AA = MA  (always true for if k == -1 regardless of the value of init_AA_type)
                                                           method2 =  with(penSim, MA[j])
                                                    ) 
                                             )
                                  )
                
                 
                 # May not need this anymore
                 # penSim$EAA[j] <- switch(init_EAA,
                 # 												AL = EAA_0,                       # Use preset value 
                 # 												MA = penSim$MA[j])                # Assume inital EAA equals inital market value.
      
      # Year 2 and after                      
      } else {
        penSim$MA[j]  <- with(penSim, MA[j - 1] + I.r[j - 1] + C[j - 1] - B[j - 1])
        penSim$EAA[j] <- with(penSim, AA[j - 1] + I.e[j - 1] + C[j - 1] - B[j - 1])
        penSim$AA[j]  <- switch(smooth_method,
                                method1 = with(penSim, MA[j] - sum(s.vector[max(s.year + 2 - j, 1):s.year] * I.dif[(j-min(j, s.year + 1)+1):(j-1)])),  # MA minus unrecognized losses and gains
                                method2 = with(penSim, MA[j]) 
        
        
        )
      }
      
    	# TDA

    	if(j > 1){
    		
    		penSim$MA.TDA[j] <- with(penSim, MA.TDA[j - 1] + I.TDA.fixed[j - 1])
    		# 
    		# if(TDA_on & k != -1){
    		# penSim$MA[j]  <- with(penSim, MA[j] + I.dif.TDA[j - 1])  
    		# penSim$AA[j]  <- switch(TDA_smooth_on,
    		# 												on  = with(penSim, AA[j] + I.dif.TDA[j - 1] - sum(s.vector.TDA[max(s.year.TDA + 2 - j, 1):s.year.TDA] * I.dif.TDA[(j-min(j, s.year.TDA + 1)+1):(j-1)])),  # MA minus unrecognized losses and gains
    		# 												off = with(penSim, AA[j] + I.dif.TDA[j - 1])
    		# )}
    		
    	}
    	
    	
    	
    	
      ## Incorporating initial unrecognized returns
       # - The unrecognized returns/losses, which are the differences between initial MA and AA, 
    	 #   will be recognized over time. 
    	 # - The schedule is constructed based on info in plan document and the asset smoothing policy
    	 # - The schedule from the plan document is adjusted for the MA-AA difference in the model, which may not be always equal to the document value. 
    	
    	if((init_AA_type %in% c("AL_pct", "AA0")) & useAVunrecReturn & k != -1 ){  #    & Tier_select_ == "sumTiers"
       
        # Adjusting initila unrecognized returns for the MA-AA difference in the model
        init_unrecReturns.adj <-  mutate(init_unrecReturns.unadj_, DeferredReturn = DeferredReturn * (penSim$MA[1] - penSim$AA[1])/sum(DeferredReturn),
                                                                   DeferredReturn.annualTot = sum(DeferredReturn) - cumsum(DeferredReturn) # Initial unrecognized return to be subtracted from AA in each year
                                         )

        # Adjust AA for inital unrecognized returns
        if((j - 1 + init_year) %in% init_unrecReturns.adj$year) penSim$AA[j] <- penSim$AA[j] - with(init_unrecReturns.adj, DeferredReturn.annualTot[year == (j - 1 + init_year)])
      }
        
      
    	
      ## Apply corridor for MA, MA must not deviate from AA by more than 20%.
    	
    	if(corridor){
        penSim$AA[j] <- with(penSim, ifelse(AA[j] > s.upper * MA[j], s.upper * MA[j], AA[j])) 
        penSim$AA[j] <- with(penSim, ifelse(AA[j] < s.lower * MA[j], s.lower * MA[j], AA[j]))
    	}

      # UAAL(j)
      penSim$UAAL[j]    <- with(penSim, AL[j] - AA[j])
  
      
      
      #******************************************
      #   2. Losses/gains and amoritization    **
      #******************************************
      
      # Notes on useAVamort
      # if useAVamort is FALSE: It is assumed that the entire UAAL in year 1 is the loss/gain that occurs in year 0
      #                         It is then amortized using the amortization policy. 
      #
      # if useAVamort is TRUE:  Use the schedule of losses/gains and amortization payments from the plan documeht. 
      
      
      # LG(j)
      # Note that what is amortized at time t is the sum of 1) actuarial loss/gain(LG) during t -1, and 2) shortfall in paying ADC(C_ADC) at (t-1)
      if (j == 1){
        penSim$EUAAL[j]       <- 0
        penSim$LG[j]          <- with(penSim, UAAL[j])  # This is the intial underfunding, rather than actuarial loss/gain if the plan is established at period 1. 
        penSim$Amort_basis[j] <- with(penSim, LG[j])    
        
      } else {
        penSim$EUAAL[j]       <- with(penSim, (UAAL[j - 1] + NC[j - 1])*(1 + i[j - 1]) - C[j - 1] - Ic[j - 1])
        penSim$LG[j]          <- with(penSim,  UAAL[j] - EUAAL[j])
        penSim$Amort_basis[j] <- with(penSim,  LG[j] - (C_ADC[j - 1]) * (1 + i[j - 1]))
      }   
      
      
      # # Amortize LG(j)
    
      #if(j > 1){
      if(j > ifelse(useAVamort, 1, 0)){
        # if useAVamort is TRUE, AV amort will be used for j = 1, not the one calcuated from the model. This may cause inconsistency in the model results(?)
        if(amort_type == "closed") SC_amort[nrow.initAmort + j - 1, j:(j + m - 1)] <- amort_LG(penSim$Amort_basis[j], i, m, salgrowth_amort, end = FALSE, method = amort_method, skipY1 = OYLM_skipY1)
        }
      #}
      
      # Supplemental cost in j
      penSim$SC[j] <- switch(amort_type,
                             closed = sum(SC_amort[, j]),
                             open   = amort_LG(penSim$UAAL[j], i, m, salgrowth_amort, end = FALSE, method = amort_method, skipY1 = FALSE)[1])
      
      
      
      
      
      #******************************************
      #   3. ADC, ERC, and total contribution  **
      #******************************************
      # Notes on nonNegC and EEC_fixed
      
      
      # # EEC(j)
      # penSim$EEC[j] <- with(penSim, PR[j] * EEC_rate)
      
      
      # ADC(j) no OYLM
     
      if(nonNegC){
        #penSim$ADC[j]    <- with(penSim, max(0, NC[j] + SC[j])) 
        #penSim$ADC.ER[j] <- with(penSim, ifelse(ADC[j] > EEC[j], ADC[j] - EEC[j], 0)) 
        
      	
      	
      	# OYLM *******************************************************************
        
      	penSim$ADC_current[j]    <- with(penSim, max(0, NC[j] + SC[j]))
        penSim$ADC.ER_current[j] <- with(penSim, ifelse(ADC_current[j] > EEC[j], ADC_current[j] - EEC[j], 0)) 
        
        # ADC(j) with OYLM
        # NC, SC, EEC
        # noNegC = TRUE and Fixed_EEC = TRUE by default
        
        if(j >=2){
        	penSim$ADC.ER_lag[j] <- with(penSim,  ADC.ER_current[j - 1] * (1 + 0)) 
        	penSim$ADC_lag[j]    <- with(penSim,  EEC[j] + ADC.ER_lag[j])
        	
        } else {
        	penSim$ADC.ER_lag[j] <- with(penSim,  ADC.ER_current[j])
        	penSim$ADC_lag[j]    <- with(penSim, EEC[j] + ADC.ER_lag[j])
        }
        
        
        # Use OYLM or not 
        
        if (k != -1 & OYLM_on) {
        	penSim$ADC[j]    <- penSim$ADC_lag[j]
        	penSim$ADC.ER[j] <- penSim$ADC.ER_lag[j]
        } else {
        	penSim$ADC[j]    <- penSim$ADC_current[j]
        	penSim$ADC.ER[j] <- penSim$ADC.ER_current[j]
        }
        
        
        # End of OYLM ************************************************************
        
        
        # Adjustment of EEC
        if(!EEC_fixed) penSim$EEC[j] <- with(penSim, ifelse(ADC[j] > EEC[j], EEC[j], ADC[j])) # penSim$EEC[j] <- with(penSim, EEC[j]) else
        
      } else {
        # Allow for negative ADC and C  
        penSim$ADC[j]    <- with(penSim, NC[j] + SC[j]) 
        
        if(EEC_fixed) {penSim$ADC.ER[j] <- with(penSim, ADC[j] - EEC[j]) # EEC is fixed
        # EEC is not fixed
          # 1. when ADC > EEC. Employees pay fixed EEC and employer pays the rest
        } else if(with(penSim, ADC[j] > EEC[j])) {
          penSim$ADC.ER[j] <- with(penSim, ADC[j] - EEC[j]) 
          # 2. when 0 < ADC < EEC. Employees pay the entire ADC and employer pays 0. 
        } else if(with(penSim, ADC[j] <= EEC[j] & ADC[j] > 0)) {
          penSim$ADC.ER[j] <- 0
          penSim$EEC[j]    <- with(penSim, ADC[j])
          # 3. when ADC < 0, employees pay zero and employer pays nagative value (withdraw -ADC)
        } else if(with(penSim, ADC[j] <= 0)) {
          penSim$ADC.ER[j] <- with(penSim, ADC[j])
          penSim$EEC[j]    <- 0
        }
        
      }
      
      

      
      # ERC
      penSim$ERC[j] <- switch(ConPolicy,
                              ADC     = with(penSim, ADC.ER[j]),                          # Full ADC
                              ADC_cap = with(penSim, min(ADC.ER[j], PR_pct_cap * PR[j])), # ADC with cap. Cap is a percent of payroll 
                              Fixed   = with(penSim, PR_pct_fixed * PR[j])                # Fixed percent of payroll
      ) 
      
      
     
      
      # C(j)
      
      penSim$C[j] <- with(penSim, EEC[j] + ERC[j])
      	

      # C(j) - ADC(j)
      penSim$C_ADC[j] <- with(penSim, C[j] - ADC[j])
      
      
      
      
      #******************************************
      #   4. Investment income                 **
      #******************************************
      
      # Ia(j), Ib(j), Ic(j) Components of expected investment income
      penSim$Ia[j] <- with(penSim,  MA[j] * i[j])
      penSim$Ib[j] <- with(penSim,  B[j] * i[j])
      penSim$Ic[j] <- with(penSim,  C[j] * i[j])
      
      
      # I.e(j) Expected investment income
      penSim$I.e[j] <- with(penSim, i[j] *(MA[j] + C[j] - B[j]))
      
      
      # I.r(j) Actual investment income
      penSim$I.r[j] <- with(penSim, i.r[j] *( MA[j] + C[j] - B[j]))   # C[j] should be multiplied by i.r if assuming contribution is made at year end. 
      

      penSim$I.TDA.fixed[j]  = with(penSim, MA.TDA[j] * i.TDAfixed)
      penSim$I.TDA.actual[j] = with(penSim, MA.TDA[j] * i.r[j])
      penSim$I.dif.TDA[j]    = with(penSim, I.TDA.actual[j] - I.TDA.fixed[j])
      penSim$i.r.wTDA[j]     = with(penSim, (I.r[j] + I.dif.TDA[j]) / ( MA[j] + C[j] - B[j]))
     
      
      if(TDA_on & k != -1) penSim$I.r[j] <- penSim$I.r[j] +  penSim$I.dif.TDA[j]
       
      # I.dif(j) = I.r(j) - I.e(j): Difference between expected and actual investment incomes (for asset smoothing)
      penSim$I.dif[j] <- with(penSim, I.r[j] - I.e[j])
      
      
       
    }
    
    # penSim_results[[k]] <- penSim
    as.data.frame(penSim)
  }
  
  
  stopCluster(cl)
  

  
  #*************************************************************************************************************
  #                                  Combining results into a data frame.   ####
  #*************************************************************************************************************
  
  
  penSim_results <- bind_rows(penSim_results) %>% 
    mutate(sim     = rep(-1:nsim, each = nyear),
           runname = runname,
           Tier    = tier_select_,
    			 OYLM_on    = OYLM_on,
    			 OYLM_skipY1 = OYLM_skipY1,
    			 TDA_policy = TDA_policy,
    			 return_scenario = return_scenario, 
           FR      = 100 * AA / exp(log(AL)),
           FR_MA   = 100 * MA / exp(log(AL)),
           UAAL_PR = 100 * UAAL / PR,
           MA_PR   = 100 * MA / PR,
           AA_PR   = 100 * AA / PR,
           AL_PR   = 100 * AL / PR,
           AL.act_PR    = 100 * AL.act / PR,
           AL.la_PR    = 100 * AL.la / PR, 
           # AL.ca_PR    = 100 * AL.ca / PR, 
           AL.term_PR   = 100 * AL.term / PR, 
           #AL._PR    = 100 * AL.Ben / PR,
           ADC_PR  = 100 * ADC / PR,
           NC_PR   = 100 * NC / PR,
           NC.laca_PR    = 100 * NC.laca / PR,
           NC.v_PR   = 100 * NC.v / PR,
           SC_PR   = 100 * SC / PR, 
           ERC_PR  = 100 * ERC / PR,
           EEC_PR  = 100 * EEC / PR,
    			 
    			 ERC_noTDA_PR  = 100 * ERC / PR,
    			 C_noTDA_PR    = 100 * C   / PR,
    			 
           C_PR    = 100 * C / PR,
           B_PR    = 100 * B / PR,
           ExF     = C - B,
           ExF_PR  = 100 * ExF / PR,
           ExF_MA  = 100 * ExF / MA, 
           PR.growth = ifelse(year > 1, 100 * (PR / lag(PR) - 1), NA),
    			 
    			 MA.TDA_QPP = MA.TDA / MA,
    			 i.leverage = i.r.wTDA - i.r,
    			 
    			 termCost_UFT = MA.TDA * share_UFT * 0.0125
    			 
           ) %>%
    select(runname, sim, year, everything())
  
  return(penSim_results)
  
}






