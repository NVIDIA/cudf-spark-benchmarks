WITH RankedOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSpenders AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        roi.c_custkey,
        roi.c_name,
        roi.total_spent
    FROM 
        RankedOrders roi
    JOIN 
        supplier s ON roi.c_custkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        roi.rank_spending <= 5
)
SELECT 
    ts.region_name,
    ts.nation_name,
    COUNT(ts.c_custkey) AS number_of_top_spenders,
    AVG(ts.total_spent) AS avg_spent
FROM 
    TopSpenders ts
GROUP BY 
    ts.region_name, ts.nation_name
ORDER BY 
    ts.region_name, avg_spent DESC;
