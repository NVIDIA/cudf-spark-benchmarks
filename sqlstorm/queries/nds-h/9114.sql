WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cs.region_name,
    cs.nation_name,
    COUNT(DISTINCT cs.c_custkey) AS total_customers,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(os.total_revenue) AS total_revenue,
    AVG(ss.average_supply_cost) AS average_supply_cost
FROM 
    CustomerRegion cs
LEFT JOIN 
    OrderStats os ON cs.c_custkey = os.o_orderkey
LEFT JOIN 
    SupplierStats ss ON os.o_orderkey % ss.s_suppkey = 0
GROUP BY 
    cs.region_name, cs.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 10;