# Random forest with five-fold cross validation

rm(list = ls())
ptm <- proc.time()

library(randomForest)
library(ROCR)
library(MLmetrics)
library(mRMRe)
#set.seed(1)

meanAUC = 0
for (i in 1:5) {
  set.seed(1)
  mydata = read.table(paste0('res_m1_data_train', i, '.txt'), header = FALSE)
  mydata = data.matrix(mydata)
  s1Tr = nrow(mydata)
  s2Tr = ncol(mydata)
  yTr = mydata[, 1]
  yTrFac = as.factor(mydata[, 1])
  xTr = mydata[, 2:s2Tr]
  
  mydata = read.table(paste0('res_m1_data_test', i, '.txt'), header = FALSE)
  mydata = data.matrix(mydata)
  s1Te = nrow(mydata)
  s2Te = ncol(mydata)
  yTe = mydata[, 1]
  yTeFac = as.factor(mydata[, 1])
  xTe = mydata[, 2:s2Te]
  
  # Feature selection
  df = data.frame(yTr, xTr)
  dd = mRMR.data(data = df)
  sel = mRMR.ensemble(data = dd, target_indices = c(1), solution_count = 1, feature_count = 150)
  feaInd = sel@filters[[1]] - 1
  
  rfModel <- randomForest(xTr[, feaInd], yTrFac, ntree = 500, mtry = 5, importance = TRUE)
  pred <- predict(rfModel, xTe[, feaInd])
  #print(table(observed = yTeFac, predicted = pred))
  
  probMat <- predict(rfModel, xTe[, feaInd], type = 'prob')
  prob = probMat[, 2]
  
  predObj <- prediction(prob, yTe)
  perf <- performance(predObj, "tpr", "fpr")
  
  spe = 1 - perf@x.values[[1]]
  sen = perf@y.values[[1]]
  speSenSum = sen+spe
  iuiuYouden = data.frame(sen, spe, speSenSum)
  
  rNames = c('auc', 'sen', 'spe', 'f1', 'precision');
  resMetrics = matrix(0, nrow = length(rNames), ncol = 1, dimnames = list(rNames, c()))
  resMetrics[1] = AUC(y_pred = prob, y_true = yTe)
  resMetrics[2] = Sensitivity(y_pred = pred, y_true = yTe, positive = "1")
  resMetrics[3] = Specificity(y_pred = pred, y_true = yTe, positive = "1")
  confMat_iuiu = ConfusionMatrix(y_pred = pred, y_true = yTe)
  
  resMetrics[4] = F1_Score(y_pred = pred, y_true = yTe, positive = "1")
  resMetrics[5] = Precision(y_pred = pred, y_true = yTe, positive = "1")
  print(resMetrics)
  
  # Plot roc
  par(pty="s")
  plot(perf, asp=1)
  text(0.5, 0.1, paste0('AUC=', resMetrics[1]), pos = 4, cex = 1)
  grid()
  
  meanAUC = meanAUC + resMetrics[1]
  save(resMetrics, iuiuYouden, rfModel, file = paste0('res_m2_randomForest', i, '.RData'))
}

meanAUC = meanAUC/5
print(paste0('mean AUC of five-fold cross validation is: ', meanAUC))

print(proc.time() - ptm)