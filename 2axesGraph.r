#----------------------------------
# code used to graph in R two Y-axes  (the jitter value in log scale and the number of AP)
# and in x-axe is the number of message


path <- "/home/jorlu/Escritorio/test/"
consumtime <- read.table("/home/jorlu/Escritorio/test/consumerT3.csv",header=TRUE, sep="\t",na.strings="NA",dec=".",strip.white=TRUE)
apes <- read.table("/home/jorlu/Escritorio/resum.csv",header=TRUE, sep=",",na.strings="NA",dec=".",strip.white=TRUE)


i=14
nameins   <- paste("test",i,sep="")
filename  <- paste(path,nameins,sep="")
outfilePNG <- paste(filename,".png",sep="")
png(outfilePNG)

x<-consumtime$message
y<-consumtime$t14
y2<-apes$t14[1:298]
plot(x,y1, log="y1")
plot(x, y, log="y", xlab="message", ylab="log(jitter)",ylim=c(1,1000000))

par(new=TRUE)
plot(x, y2,,type="l",col="blue",xaxt="n",yaxt="n",xlab="",ylab="")
axis(4)
mtext("AP",side=4,line=3)

dev.off( )

#------------------------------------------------------
