# # Script de Evaluación de inflación basada en percentiles (Equiponderados y ponderados)
using DrWatson
using DataFrames
using Plots, CSV
@quickactivate "HEMI"

# Cargar el módulo de Distributed para computación paralela
using Distributed
# Agregar procesos trabajadores
addprocs(4, exeflags="--project")

# Cargar los paquetes utilizados en todos los procesos
@everywhere using HEMI

# CountryStructure con datos hasta diciembre de 2020
# gtdata_eval = gtdata[Date(2020, 12)]
gtdata_eval = gtdata[Date(2019, 12)]

##
# Percentiles ponderados

# 1. Definir los parámetros de evaluación. 

# Asumimos que queremos evaluar los percentiles ponderados del 50 al 80. 
# Generamos el diccionario con los parámetros de evaluación.
# utilizamos los mismos datos gtdata_eval = gtdata[Date(2020, 12)]

# Funciones de remuestreo y tendencia
# resamplefn = ResampleSBB(36)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# la función de inflación, la instanciamos dentro del diccionario.
dict_percW = Dict(
    :inflfn => InflationPercentileWeighted.(50:80), 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :nsim => 125_000) |> dict_list # 125_000


# 2. Definimos las carpetas para almacenar los resultados 
savepath_pw = datadir("InflationPercentileWeighted","scramble")
savepath_plot_pw = plotsdir("InflationPercentileWeighted","scramble","MSE")

# 3. Usamos run_batch, para gnenerar la evaluación de los percentiles del 50 al 80
run_batch(gtdata_eval, dict_percW, savepath_pw, param_constructor_fn=ParamTotalCPILegacyRebase, rndseed = 0)

# 4. Revisión de resultados, usando collect_results
df_pw = collect_results(savepath_pw)

# Revisamos el elemento del DataFrame con el valor mínimo de mse
min_mse_pw= minimum(df_pw[!,"mse"])

# Podemos ordenar el DataFrame respecto al mse.
sorted_df_pw = sort(df_pw, "mse")
min_pw= first(sorted_df_pw[!,"measure"])

# Guardar el DataFrame en la ruta especifiada
CSV.write(string(savepath_pw,"//InflationPercentileWeighted.csv"),sorted_df_pw)

# revisión gráfica

scatter(50:80, df_pw.mse, 
    ylims = (0, 15),
    label = " MSE Percentiles Ponderados", 
    legend = :topright, 
    xlabel= "Percentil ponderado", ylabel = "MSE")
    annotate!(70, 12, string("min MSE = ",min_mse_pw,"  ",min_pw),7)
    png(savepath_plot_pw)


##
# Percentiles Equiponderados

# 1. Definir los parámetros de evaluación. 

# Asumimos que queremos evaluar los percentiles ponderados del 50 al 80. 
# Generamos el diccionario con los parámetros de evaluación.
# utilizamos los mismos datos gtdata_eval = gtdata[Date(2020, 12)]

# Funciones de remuestreo y tendencia
# resamplefn = ResampleSBB(36)
resamplefn = ResampleScrambleVarMonths()
trendfn = TrendRandomWalk()

# la función de inflación, la instanciamos dentro del diccionario.
dict_perc = Dict(
    :inflfn => InflationPercentileEq.(50:80), 
    :resamplefn => resamplefn,
    :trendfn => trendfn,
    :nsim => 125_000) |> dict_list # 125_000


# 2. Definimos las carpetas para almacenar los resultados 
savepath_p = datadir("InflationPercentileEq","scramble")
savepath_plot_p = plotsdir("InflationPercentileEq","scramble","MSE")

# 3. Usamos run_batch, para gnenerar la evaluación de los percentiles del 50 al 80
run_batch(gtdata_eval, dict_perc, savepath_p, param_constructor_fn=ParamTotalCPILegacyRebase, rndseed = 0)

# 4. Revisión de resultados, usando collect_results
df_p = collect_results(savepath_p)

# Revisamos el elemento del DataFrame con el valor mínimo de mse
min_mse_p= minimum(df_p[!,"mse"])

# Podemos ordenar el DataFrame respecto al mse.
sorted_df_p = sort(df_p, "mse")
min_p= first(sorted_df_p[!,"measure"])

# Guardar el DataFrame en la ruta especifiada
CSV.write(string(savepath_p,"//InflationPercentileEq.csv"),sorted_df_p)

# revisión gráfica

scatter(50:80, df_p.mse, 
    ylims = (0, 20),
    label = " MSE Percentiles Equiponderados", 
    legend = :topright, 
    xlabel= "Percentil Equiponderado", ylabel = "MSE")
    annotate!(70, 16, string("min MSE = ",min_mse_p,"  ",min_p),7)
    png(savepath_plot_p)


