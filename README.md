# chatR
chatR is the package version of CHAT. It allows easy loading of cllimate models and the output of the load_data function is used as input for the remaining functions of the chatR package. 
chatR can be seen as a wrapper of several packages, but the main engine for loading and processing climate models is the 
## Working examples

### Installation

``` 
library(devtools)
install_github("Risk-Team/chatR")
```
### Loading example data

``` 
fpath <- system.file("extdata/", package="chatR")
exmp <- load_data(country = "Moldova", variable="hurs", n.cores=6,
              path.to.rcps = fpath)

```

### Visualizing climate projections

``` 


```
