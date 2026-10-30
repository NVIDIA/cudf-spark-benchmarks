WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationDetails AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    nd.n_name AS Nation, 
    sd.s_name AS Supplier, 
    SUM(os.total_revenue) AS Total_Revenue, 
    SUM(sd.total_supply_cost) AS Total_Supply_Cost
FROM 
    OrderStats os
JOIN 
    customer c ON os.o_custkey = c.c_custkey
JOIN 
    SupplierDetails sd ON sd.s_nationkey = c.c_nationkey
JOIN 
    NationDetails nd ON c.c_nationkey = nd.n_nationkey
GROUP BY 
    nd.n_name, sd.s_name
ORDER BY 
    Total_Revenue DESC, Total_Supply_Cost DESC
LIMIT 10;