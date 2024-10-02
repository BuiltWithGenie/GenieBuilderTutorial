module App
# == Packages ==
# set up Genie development environment. Use the Package Manager to install new packages
using GenieFramework, Dates, PlotlyBase, DataFrames
@genietools

# == Code import ==
# add your data analysis code here or in the lib folder. Code in lib/ will be
# automatically loaded into the Main scope
function data_analysis()
    return "Mockup data analysis function"
end

# Data import and definition
const data = sort!(DataFrame(rand(1_000, 2), ["x1", "x2"]))::DataFrame


# == Reactive code ==
# add reactive code to make the UI interactive
@app begin
    # == Reactive variables ==
    # reactive variables exist in both the Julia backend and the browser with two-way synchronization
    # @out variables can only be modified by the backend
    # @in variables can be modified by both the backend and the browser
    # variables must be initialized with constant values, or variables defined outside of the @app block
    @in A =  0.0
    @out B = 8
    @out C = 0.0
    # == Reactive handlers ==
    # reactive handlers watch a variable and execute a block of code when
    # its value changes
    @onchange A, B begin
        C = A+B
    end

    # Inputs
    @in checked = false
    @in radio = "radio_1"
    @in N = 0
    @out choices = ["A", "B", "C"]
    @in selected_choice = "A"
    @in trigger = false
    @in date_text = string(today())
    @in time_text = string(Dates.Time(20,23,5))
    @in range = RangeData(1:5)
    @in input_text = "Hello"

    # Buttons have specific handlers that reset the boolean variable to false at the end
    @onbutton trigger begin
      sleep(3)
    end

    # Plots are configured by binding vector data to the axes. In the visual editor, you can select 
    # data from vectors and DataFrame columns
    @out x = collect(1:10)
    @out y = randn(10) 
    # @out M = DataFrame(x=collect(1:10), y=randn(10))  # DataFrame example
    @in add_data = false
    @in reset_data = false
    # How to update array data
    @onbutton add_data begin
      push!(x, length(x)+1)    # This will not trigger an update in the UI
      @push x               # This will send the value to the UI
      y = vcat(y, randn(1)) # Variable reassignments also trigger UI updates
    end
    @onbutton reset_data begin
      x = Int32[]
      y = Float64[]
    end

    # PlotlyBase plots
    # You can also define the traces and layout of the plot and use the Bound Plot component
    # Useful when you have a dynamic number of traces
    @out traces = [scatter(x=collect(1:10),y=randn(10))] # always an array of traces
    @out layout = PlotlyBase.Layout(title="My Plot", xaxis_title="x", yaxis_title="y")
    @in N_traces = 1
    # Adding N traces in a loop
    @onchange N_traces begin
      traces[!] = [] # With the [!] suffix we reassign the array without triggering a UI update
      for i in 1:N_traces
        push!(traces, scatter(x=collect(1:10), y=randn(10)))
      end
      @push traces   # Update the traces vector when all traces are generated
    end
    
    # Flow control
    @in show = true
    @in N_blocks = 3
    @out indexes = [1,2,3] # remember, you can't initialize with other reactive variables (N_blocks in this case)
    @onchange N_blocks begin
      indexes = collect(1:N_blocks)
    end

    # Tabs
    @out tab_ids =  ["tab_cars", "tab_scooters", "tab_bikes"]
    @out tab_labels = ["Cars", "Scooters", "Bikes"]
    @in selected_tab =  "tab_cars"

    # Table
    @out dt1 = DataTable(data)

    # Table with server-side pagination.
    # First, add this at the top of this file to limit the number of rows sent to the browser:
    # StippleUI.Tables.set_default_rows_per_page(20)
    # StippleUI.Tables.set_max_rows_client_side(100)
    @out dt2 = DataTable(data; server_side = true)
    @out loading_table = false
    # The dt2_request event is triggered when the pagination button is clicked on the table
    # This @event will update the table with the new page
    @event dt1_request begin
      loading_table = true
      dt2 = @paginate(dt2, data)
      @push dt2
      loading_table = false
    end

end

# == Pages ==
# register a new route and the page that will be loaded on access
@page("/", "app.jl.html")
end

# == Advanced features ==
#=
- The @private macro defines a reactive variable that is not sent to the browser. 
This is useful for storing data that is unique to each user session but is not needed
in the UI.
    @private table = DataFrame(a = 1:10, b = 10:19, c = 20:29)

=#
