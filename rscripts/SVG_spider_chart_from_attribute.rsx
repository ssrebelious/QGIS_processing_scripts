##Plotting = group
##layer=vector
##ID=field layer
##start_field= field layer
##end_field= field layer
##add_ghost_data=boolean True
##total_bins_including_ghosts=number 20
##ghost_value=number 0
##plot_width=number 5
##plot_height=number 5
##palette=string #a6cee3,#1f78b4,#b2df8a,#33a02c,#fb9a99,#e31a1c,#fdbf6f,#ff7f00,#cab2d6,#6a3d9a,#8dd3c7,#ffffb3,#bebada,#fb8072,#80b1d3,#fdb462,#b3de69,#fccde5,#d9d9d9,#bc80bd
##out_folder=folder
##showplots

library(ggplot2)
library(reshape2)
library(grid)

# R не допускает пробелов в именах атрибутов, а аткже начала имени атрибута с цифры.
# Необходимо привести загруженные в R имена атрибутов в соответсвие с их именами в векторном слое
fixFieldName <- function(field_name){
field_name <- gsub(' ', '.', field_name)
if( is.na(as.integer(substr(field_name,1,1))) == F ) {
    field_name <- paste('X', field_name, sep = '')
    }
    field_name
}

palette <- strsplit(palette, ',')
palette_1 <- c()

# Processing удаляет знак '#' из строки параметров - надо это исправить
for (i in palette) {
    char = substr(i,1,1)
    print(char)
    if ( char != '#') {
    colour <- paste('#', i, sep = '')
    palette_1 <- c(palette_1, colour)
    }
}

palette <- palette_1

# Processing не добавляет слеш в конец адреса папки. Надо это исправить.
slash <- substr(out_folder, nchar(out_folder), nchar(out_folder))
if (slash != '/' | slash != '\\' ) {
    out_folder <- paste(out_folder, '/', sep = '')
}

ID <- fixFieldName(ID)
start_field <- fixFieldName(start_field)
end_field <- fixFieldName(end_field)

dFrame <- as.data.frame(layer)
ID <- match(ID, names(dFrame))
start_field <- match(start_field, names(dFrame))
end_field <- match(end_field, names(dFrame))
print(start_field)
print(end_field)
max_value <- max(dFrame[,start_field:end_field])

addGhostData <- function(temp_df, d_value = 0, n_bins = 20){
    # Эта функция добавляет несуществующие данные
    temp_df$variable <- as.character(temp_df$variable) # we want to be able to add some rows

    # ensure that there are 20 instances to plot
    if (total_columns < n_bins) {
    for (col in (total_columns + 1):n_bins) {
    row <- c(paste('X', 'ZZ99', col, sep = ''), d_value) # need to add 'X' because the other variables in this column have this prefix
    temp_df <- rbind(temp_df, row)
        }
    }

# fix dataframe
temp_df$variable <- as.factor(temp_df$variable)
temp_df$value <- as.integer(temp_df$value)
temp_df
}

for (i in c( 1:nrow(dFrame) ) ) {

    # preprocess data
    total_columns <- end_field - start_field +1
    temp_df <- dFrame[,start_field:end_field][i,]
    temp_df <- melt(temp_df)
    
    # add rows if there needed
    if (add_ghost_data) {
    temp_df <- addGhostData(temp_df, ghost_value, total_bins_including_ghosts)
    }


    # create plot
    p <- ggplot(temp_df, aes(x = variable, y = value)) +
        geom_bar(aes(fill = variable), colour = 'white', stat="identity")+
        coord_polar()+
        ylim(0, max_value)+ # set y limits so all charts will be comparable
        theme(axis.text.x = element_blank(),#element_text(angle=0, hjust = NULL, size = 10, color = 'black'),
        axis.text.y = element_blank(),#element_text(angle=0, hjust = NULL, size = 10, color = 'black'),
        axis.title = element_blank(),#element_text(face = 'bold', size = 16),
        axis.ticks = element_blank(),
        title = element_text(face = 'bold', size = 16),
        legend.position = 'none',
        legend.title = element_blank(),
        legend.text = element_text(size = 10),
        plot.margin = unit(c(0,0,-0.3,-0.3), 'cm'), # cut the margins!!!
        plot.background = element_blank(), # plot background transparent
        panel.background = element_blank(), # chart background transparent
        panel.grid = element_blank() #comment this line and delete comma in the line above to have a grid
        )+
        labs(x=NULL, y=NULL, title = NULL)+
        scale_fill_manual(values = palette)


    # create filename
    fid <- dFrame[,ID][i]
    file_name <- paste(out_folder, fid, '.svg', sep = '')
    
    # save chart
    ggsave(file = file_name, plot = p, width = plot_width, height = plot_height, units = 'cm', bg = "transparent")

}


#create reference plot
temp_df <- dFrame[,start_field:end_field]
l <- list(NULL)
for ( i in (1:ncol(temp_df)) ){l[[i]] = max_value}

temp_df <- rbind(temp_df, l)
row <- nrow(temp_df)
new_df <- temp_df[row,]
new_df <- melt(new_df)

# add rows if there are less than 20 of them
if (add_ghost_data) {
    new_df <- addGhostData(new_df, max_value, total_bins_including_ghosts)
}

# rename variables in rows to remove 'X' infront of numbers
new_df$variable <- as.character(new_df$variable)
for (i in (1:nrow(new_df))) {
variable <- new_df[,1][i]
print(variable)
new_df[,1][i] <- substr(variable, 2, nchar(variable))
}
new_df$variable <- as.factor(new_df$variable)

# plot reference chart
p <- ggplot(new_df, aes(x = variable, y = value)) +
    geom_bar(aes(fill = variable), colour = 'white', stat="identity")+
    coord_polar()+
    ylim(0, max_value)+ # set y limits so all charts will be comparable
    labs(title = 'Reference chart',
    legend = 'Attribute') +
    theme(axis.text.x = element_text(angle=0, hjust = NULL, size = 10, color = 'black'),
    axis.text.y = element_text(angle=0, hjust = NULL, size = 10, color = 'black'),
    axis.title = element_blank(),#element_text(face = 'bold', size = 16),
    title = element_text(face = 'bold', size = 16),
    legend.position = 'right',
    legend.title = element_blank(),#element_text(angle=0, hjust = NULL, size = 14, color = 'black'),
    legend.text = element_text(size = 10)
    )+
    scale_fill_manual(values = palette)

plot(p)
