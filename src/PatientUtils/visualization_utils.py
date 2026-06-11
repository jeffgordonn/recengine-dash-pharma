import plotly 
import plotly.graph_objs as go
from sklearn.preprocessing import StandardScaler
from scipy.cluster.hierarchy import sch
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import numpy as np
from datetime import datetime as dt
import ML_utils as mut




def checkNormalization(df:pd.DataFrame,feature:str):
    import matplotlib.gridspec as gridspec
    import matplotlib.style as style
    style.use('fivethirtyeight')
    ## chart base 
    fig = plt.figure(constrained_layout=True, figsize=(12,8)) 
    grid = gridspec.GridSpec(ncols=3, nrows=3, figure=fig)
    # histogram
    ax1 = fig.add_subplot(grid[0, :2])
    ax1.set_title('Histogram')
    sns.distplot(df.loc[:,feature], norm_hist=True, ax = ax1)
    # qq plot
    ax2 = fig.add_subplot(grid[1, :2])
    ax2.set_title('QQ_plot')
    stats.probplot(df.loc[:,feature], plot = ax2)
    ## box plot 
    ax3 = fig.add_subplot(grid[:, 2])
    ax3.set_title('Box Plot')
    sns.boxplot(df.loc[:,feature], orient='v', ax = ax3);

def correlationPlot(
    df:pd.DataFrame, cols:list | None = None,figsize:tuple=(16,10), title: str = 'Corr Plot', **kwargs
):
    # I would suggest somekind of ETL of string to numeric. Doesn't need to be more than str-int ID tokens
    df = df.select_dtypes(include=['numeric'])
    # explicit column declaration
    if cols:
        df = df[cols]
    # create data
    corr_matrix = df.corr()
    # set size
    plt.figure(figsize=figsize)
    # create heatmap plot
    sns.heatmap(corr_matrix,**kwargs)
    plt.title(label=title)
    plt.show()


def hexbins(df,col1,col2):
    sns.jointplot(x=df[col1],y=df[col2],kind='hex')

def scatterplot2D(
        df:pd.DataFrame, x:str, y:str, 
        title:str | None = None, **kwargs
):
    plt.scatter(df[x],df[y],**kwargs)
    if title is None:
        plt.title = f'{x} vs. {y}'
    plt.xlabel = x
    plt.ylabel = y
    plt.show()

def scatterplot3Dto6D(
        df:pd.DataFrame, x_axis:dict, y_axis:dict, z_axis:dict,
        marker_size:dict, marker_color:dict, marker_shape:dict,
        opacity:float=1.0, colorscale:str='blues', colorbar:dict={
            'title':'color','titleside':'right'
        }, standardize:bool=False, display:bool=False, save_file:str | bool = False,
        return_location: bool = False, **kwargs
):
    # copy data to manipulate
    plot_df = df.copy()
    mylayout = go.Layout()
    plotcols = []
    
    x = x_axis['column_name']
    plotcols.append(x)
    if x_axis['plot_title']: # these should be the column names
        mylayout.scene = {'xaxis':{'title':x_axis['plot_title']}}

    y = y_axis['column_name']
    plotcols.append(y)
    if y_axis['plot_title']: # these should be the column names
        mylayout.scene = {'xaxis':{'title':y_axis['plot_title']}}

    z = z_axis['column_name']
    plotcols.append(z)
    if z_axis['plot_title']: # these should be the column names
        mylayout.scene = {'xaxis':{'title':z_axis['plot_title']}}

    marker_dictpass = dict()

    if marker_size:
        markersize = marker_size['column_name']
        if marker_size['resize']:
            plot_df[markersize] *= marker_size['resize']
        plotcols.append(markersize)
        marker_dictpass['size'] = plot_df[markersize] 

    if marker_color:
        # grab passed columns
        mc_col = marker_color['column_name']
        # grab passed colors
        color_map = marker_color['colors']
        # map the colors to the columns
        markercolor = plot_df[mc_col].map(color_map)
        # for setting plot
        plotcols.append(mc_col)
        marker_dictpass['color'] = markercolor

    if marker_shape:
        # gpc
        ms_col = marker_shape['column_name']
        # gpc
        shape_map = marker_shape['shapes']
        # map them in df
        markershape = plot_df[ms_col].map(shape_map)
        # for setting plot
        plotcols.append(ms_col)
        marker_dictpass['shape'] = markershape

    # need to be able see it somehow lol
    marker_dictpass['opacity'] = max(0.1,min(opacity,1.0)) # enforces a range between 0.1 and 1
    # set colorscale
    marker_dictpass['colorscale'] = colorscale

    marker_dictpass['showscale'] = True # hardcoding
    marker_dictpass['reversescale'] = True # hardcoding # for now

    # based on the passed params, we will now set the data scope
    plot_df = plot_df[plotcols]

    # I am inclinded to actually believe in the case of this data, 
    # especially for some of the more minor corr analyses, 
    # we will want to keep the raw values BUT if we see some issues with scaling
    if standardize:
        transform = StandardScaler()
        axis = [x,y,z,markersize]
        plot_df[axis] = transform.fit_transform(plot_df[axis])

    # categorical observations do not need to be standardized
    # color is not affected by opacity, i guess potentially you could set the color gradients
    # based on continuous value which might benefit from standarization but how about yeah naw
    fig = go.Scatter3d(
        x=plot_df[x],y=plot_df[y],z=plot_df[z],
        marker=marker_dictpass,**kwargs
    )

    if display:
        disp = go.Figure(
            data=[fig],
            layout=mylayout
        )
        disp.show()

    if save_file:
        filename = rf'{len(plotcols)}D Correlation ScatterPlot{str(dt.now())}'
        plotly.offline.plot(
            {'data':[fig],'layout':mylayout},
            auto_open=False, 
            filename=(filename)
        )

    if save_file and display:
        filepath = os.path.join(os.getenv('PATIENT_DATA_DIR'),rf'{len(plotcols)}D Correlation ScatterPlot{str(dt.now())}')
        plotly.offline.plot(
            {'data':[fig],'layout':mylayout},
            auto_open=False, 
            filename=(filepath)
        )
        disp = go.Figure(
            data=[fig],
            layout=mylayout
        )
        disp.show()

    if return_location:
        print(filepath)

# for clustering     
def plotElbowMethod(inertia_values, label:None | str = None, save_directory:None | str = None):
    # create plot for inertia
    plt.figure(figsize=(8, 5))
    plt.plot(list(inertia_values.keys()), list(inertia_values.values()), 'bo-')
    plt.xlabel('Number of Clusters')
    plt.ylabel('Inertia')
    plt.title(f'Elbow Method - {label} Components')
    # save plot
    if save_directory:
        plt.savefig(f"{save_directory}/{label}_Elbow_Plot.png")

def dendrogramPlot(X:np.ndarray,method:str='Ward',savefig:bool=False,display:bool=True,**kwargs):
    plt.figure(figsize=(15, 10))
    plt.grid(False)
    Ward = sch.dendrogram(sch.linkage(X,method))
    plt.axhline(y=200,color='black')
    plt.title(f"Dendrogram Using {method}'s Method")
    plt.xlabel("Data Points")
    plt.ylabel("Distance")
    if savefig:
        plt.savefig(f"{os.environ['PATIENT_DATA_DIR']}/Images/{method + '_' + str(dt.now())}_dendrogram.png", dpi=300, bbox_inches='tight')
    if display:
        plt.show()