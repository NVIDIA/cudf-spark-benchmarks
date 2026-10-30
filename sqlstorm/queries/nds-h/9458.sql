
WITH TotalSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        t.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY t.total_revenue DESC) AS rank
    FROM 
        TotalSales t
    JOIN 
        customer c ON t.c_custkey = c.c_custkey
    WHERE 
        t.total_revenue > 10000 
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    tc.c_name,
    ts.total_revenue
FROM 
    TopCustomers tc
JOIN 
    supplier s ON tc.c_custkey = s.s_nationkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    TotalSales ts ON tc.c_custkey = ts.c_custkey
WHERE 
    tc.rank <= 10 
ORDER BY 
    r.r_name, n.n_name, ts.total_revenue DESC;
