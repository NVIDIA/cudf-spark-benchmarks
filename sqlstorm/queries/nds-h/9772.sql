WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.revenue) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    tc.c_name AS Top_Customer,
    sd.s_name AS Top_Supplier,
    ROUND(SUM(os.revenue), 2) AS Total_Revenue,
    ROUND(SUM(sd.total_supplycost), 2) AS Total_Supply_Cost,
    tc.total_revenue AS Customer_Revenue
FROM 
    TopCustomers tc
JOIN 
    OrderSummary os ON tc.c_custkey = os.o_orderkey
JOIN 
    SupplierDetails sd ON sd.total_supplycost = (
        SELECT MAX(total_supplycost) FROM SupplierDetails
    )
GROUP BY 
    tc.c_name, sd.s_name, tc.total_revenue;
