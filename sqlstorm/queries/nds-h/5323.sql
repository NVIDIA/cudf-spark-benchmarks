
WITH SalesData AS (
    SELECT 
        c.c_custkey AS custkey,
        c.c_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
), RankedSales AS (
    SELECT 
        custkey,
        c_name,
        nation_name,
        total_revenue,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS rank_within_nation
    FROM 
        SalesData
)
SELECT 
    custkey,
    c_name,
    nation_name,
    total_revenue
FROM 
    RankedSales
WHERE 
    rank_within_nation <= 5
ORDER BY 
    nation_name, total_revenue DESC;
