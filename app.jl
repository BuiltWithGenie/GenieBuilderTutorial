#=
# Genie Builder apps are implemented with two files:
# app.jl: the main entry point to the app. It is the bridge between the UI and your Julia code, and implements
#         the logic to handle the UI interactivity.
# app.jl.html: implements the UI in HTML. Shouldn't be edited manually, use the visual editor instead.
=#
module App
# == Packages ==
# Import the necessary packages. Use the Package Manager to install new packages
using GenieFramework, Dates, PlotlyBase, DataFrames
# Modules placed in the lib folder are automatically loaded into the Main scope. You may
# also define your functions in the app.jl file
using Main.Lib
@genietools

# == Configuration options ==
# You can add your own CSS and JS files from the public/ folder or form a URL
Stipple.Layout.add_css("/css/my_css.css")
Stipple.Layout.add_script("https://cdn.tailwindcss.com")
# Some components have helper functions for their configuration
StippleUI.Tables.set_default_rows_per_page(20)
# Configure table server-side pagination
StippleUI.Tables.set_max_rows_client_side(100)

# == Data import and definitions ==
const data = sort!(DataFrame(rand(1_000, 2), ["x1", "x2"]))::DataFrame
const my_constant = 4

# == Reactive code ==
# Add reactive code to make the UI interactive
@app begin
    # == Reactive variables ==
    # Reactive variables exist in both the Julia backend and the browser with two-way synchronization
    # Each user session has its own copy of the reactive variables
    # @out variables can only be modified by the backend
    # @in variables can be modified by both the backend and the browser
    # IMPORTANT: variables must be initialized with constant values, or variables defined outside of the @app block
    @in A =  0.0
    @out B = 8
    @out C = 0.0
    @out msg = ""
    # == Reactive handlers ==
    # Reactive handlers watch a variable and execute a block of code when
    # its value changes
    @onchange A, B begin
        @notify("Handler triggered.")
        C = data_analysis(A, B) # data_analysis is defined in the lib folder
    end
    # You can also trigger handlers from another handler by changing the associated variable
    @onchange C begin
        msg = "C changed to $C"
    end
    # == Private variables ==
    # Private variables are not sent to the browser. This useful for storing data that is unique to each user session
    @private D = 0
    # They behave like reactive variables, so you can also attach handlers to them. Since they are not present in the 
    # browser, they can only be modified in the Julia code
    @onchange D begin
        println("D changed to $D")
    end

    # == Inputs ==
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

    # == Plots ==
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
    @out traces = [scatter(x=collect(1:10),y=randn(10)),scatter(x=collect(1:10),y=randn(10))] # always an array of traces
    # The layout can also be configured in the Layout tab in the plot's properties in the visual editor
    # @out layout = PlotlyBase.Layout(title="My Plot", xaxis_title="x", yaxis_title="y")
    @in N_traces = 1
    # Adding N traces in a loop
    @onchange N_traces begin
      traces[!] = [] # With the [!] suffix we reassign the array without triggering a UI update
      for i in 1:N_traces
        push!(traces, scatter(x=collect(1:10), y=randn(10)))
      end
      @push traces   # Update the traces vector when all traces are generated
    end
    
    # == Flow control ==
    @in show = true
    @in N_blocks = 3
    @out indexes = [1,2,3] # remember, you can't initialize with other reactive variables (N_blocks in this case)
    @onchange N_blocks begin
      indexes = collect(1:N_blocks)
    end

    # == Tabs ==
    @out tab_ids =  ["tab_cars", "tab_scooters", "tab_bikes"]
    @out tab_labels = ["Cars", "Scooters", "Bikes"]
    @in selected_tab =  "tab_cars"

    # == Table ==
    @out dt1 = DataTable(data)

    # == Table with server-side pagination. ==
    @out dt2 = DataTable(data; server_side = true)
    @out loading_table = false
    # The dt2_request event is triggered when the pagination button is clicked on the table
    # This @event will update the table with the new page
    @event request begin
      @notify("Filtering table")
      loading_table = true
      dt2 = @paginate(dt2, data)
      @push dt2
      loading_table = false
    end

end

# == Pages ==
# Register a new route and the page that will be loaded on access
@page("/", "app.jl.html")
end

