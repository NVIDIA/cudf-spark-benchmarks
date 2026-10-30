WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY 
        o.o_orderkey
), 
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, n.n_name, r.r_name
)
SELECT 
    cs.c_name,
    cs.nation_name,
    cs.region_name,
    cs.total_spending,
    rs.s_name,
    rs.total_cost,
    os.total_revenue,
    os.unique_customers
FROM 
    CustomerDetails cs
JOIN 
    RankedSuppliers rs ON cs.total_spending > 100000
JOIN 
    OrderSummary os ON os.unique_customers > 10
WHERE 
    rs.cost_rank <= 5
ORDER BY 
    cs.total_spending DESC, rs.total_cost DESC;