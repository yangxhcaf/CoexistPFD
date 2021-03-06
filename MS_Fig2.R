#################################################################################
#### Coexistence theory and the frequency-dependence of priority effects 
#### Ke & Letten (2018) Nature Ecology & Evolution
#### This R script creates Figure 2 in the main text
#### Positive frequency dependence emerges from endogenously generated resource fluctuations
#################################################################################



######################################
#### Load packages
######################################
library(deSolve)
library(tidyr)
library(ggplot2)
library(cowplot)


mech.chemo.logis = function(Time, State, Pars)
{
  with(as.list(c(State, Pars)),
       {
         dN1 = N1*r1*(R^2)/(k1+R^2) - d1*N1
         dN2 = N2*r2*(R)/(k2+ R+ ((R^2)/ki2)) - d2*N2
         dR =  resR*R*(1-R/resK) - ((N1*(R^2)*r1*Q1)/(k1+R^2)) - Q2*(((N2*r2*R)/((k2)+R+((R^2)/ki2))))
         return(list(c(dN1, dN2, dR)))
       })
}


baseplot.ode = function(out.monod, Cxlim = NULL){
  par(mfrow=c(1,2))
  # Convert pop sizes less than 0.0001 to zero.
  out.monod$N1[out.monod$N1 < 0.01 & out.monod$N1 > 0] = 0
  out.monod$N2[out.monod$N2 < 0.01 & out.monod$N2 > 0] = 0
  matplot(out.monod[,1],(out.monod[,2:3]), log = "y", type="l",xlab="Time",ylab="Consumer abundance (log scale)",col=c("blue","red"),lty=1,las=1,bty='l', xlim = Cxlim)
  matplot(out.monod[,1],(out.monod[,4]),type="l",xlab="Time",ylab="Resource abundance",col=c("green"),lty=1,las=1,bty='l', xlim = Cxlim)
  par(mfrow = c(1,1))
}


## visualise functional responses
holling.sim.type3 = function(x = R, r = r, k = k){
  per.cap = r*(x)^2/((k)+(x)^2)
  return(per.cap)
}

monod.inhib = function(x = R, r = r, k = k, ki=ki){
  per.cap = r*(x)/((k)+(x) + ((x)^2)/ki2)
  return(per.cap)
}


# Set up time steps
time.total = 3000 # real length of simulation
times=round(seq(0.1,time.total,by=0.1),1) # total number of time-steps

### ODE Parameter space 
r1 = 0.029; r2 = 0.2
k1 = 0.02; k2 = 3
Q1 = 0.01; Q2 = 0.01
d1 = d2 = 0.01
ki2 = 1

#res logis
resR = 0.5
resK = 3
S = resK

#######################################
# N1 pfd
monod.ini=c(N1=500, N2=1, R=resK)

# Run the numerical simulations
out.N1wins=as.data.frame(ode(func=mech.chemo.logis,
                            y=monod.ini,
                            parms=NULL,
                            times=times,
                            method = "lsoda", events = NULL))# list(func = multieventfun, time = allevents)))

#baseplot.ode(out.N1wins, Cxlim = NULL) 
# #######################################
# #N2 pfd
monod.ini=c(N1=1, N2=500, R=resK)

# Run the numerical simulations
out.N2wins=as.data.frame(ode(func=mech.chemo.logis,
                             y=monod.ini,
                             parms=NULL,
                             times=times,
                             method = "lsoda", events = NULL))# list(func = multieventfun, time = allevents)))
#baseplot.ode(out.N2wins, Cxlim = NULL) 


# Generate ms fig 2

comp.gg = gather(out.N1wins, state.var, count, -time)
comp.plot.N1wins = ggplot(comp.gg[comp.gg$state.var != "R" & comp.gg$state.var != "E" ,], aes(y = count, x= time)) +
  geom_line(aes(group = state.var, col = state.var)) + scale_y_continuous(breaks=c(0,1,10,100,1000,4000), trans="log1p") +
  scale_color_manual(values = c("#30638e", "#d1495b")) +
  theme(legend.position="none") +
  ylab("Density") + xlab("Time") +
  panel_border(colour = "black") + 
  theme(axis.text = element_text(size = 10),
        axis.title= element_text(size = 10)) 

comp.gg = gather(out.N2wins, state.var, count, -time)
comp.plot.N2wins = ggplot(comp.gg[comp.gg$state.var != "R" & comp.gg$state.var != "E" ,], aes(y = count, x= time)) +
  geom_line(aes(group = state.var, col = state.var)) + scale_y_continuous(breaks=c(0,1,10,100,1000,4000), trans="log1p") +
  scale_color_manual(values = c("#30638e", "#d1495b")) +
  theme(legend.position="none") +
  ylab("Density") + xlab("Time") +
  panel_border(colour = "black") + 
  theme(axis.text = element_text(size = 10),
        axis.title= element_text(size = 10)) 

resource.levels = seq(0,S,by = 0.01) 
resp.blue = holling.sim.type3(x = resource.levels, r = r1, k = k1)
resp.red = monod.inhib(ki = ki2, x = resource.levels, r = r2, k = k2)
monod.mat = data.frame(resource.levels,resp.blue,resp.red)
monod.gg = gather(monod.mat, key = resp, value = count, -resource.levels)

monod.plot1 = ggplot(monod.gg, aes(y = count, x = resource.levels)) +
  geom_line(aes(col = resp)) + 
  scale_color_manual(values = c("#30638e", "#d1495b")) +
  theme(legend.position="none") + 
  xlab("Resource concentration") + ylab("Per capita growth") +
  panel_border(colour = "black") + geom_hline(yintercept = d1, linetype = "dashed") + 
  theme(axis.text = element_text(size = 10),
        axis.title= element_text(size = 10)) + ylim(0,0.05) +
  coord_cartesian(expand = FALSE)

plot_grid(monod.plot1, comp.plot.N1wins,comp.plot.N2wins, labels = c("(a)", "(b)", "(c)"), nrow = 1)
