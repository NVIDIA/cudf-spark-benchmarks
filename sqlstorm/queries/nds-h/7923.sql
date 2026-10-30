WITH RevenueCTE AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        c.c_custkey,
        c.c_name,
        rc.total_revenue
    FROM 
        RevenueCTE rc
    JOIN 
        customer c ON rc.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    ORDER BY 
        rc.total_revenue DESC
    LIMIT 10
)
SELECT 
    tc.region,
    tc.nation,
    tc.c_custkey,
    tc.c_name,
    tc.total_revenue
FROM 
    TopCustomers tc
JOIN 
    (SELECT 
        n.n_name, 
        SUM(l.l_quantity) AS total_quantity 
     FROM 
        lineitem l 
     JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
     JOIN 
        customer c ON o.o_custkey = c.c_custkey 
     JOIN 
        nation n ON c.c_nationkey = n.n_nationkey 
     GROUP BY 
        n.n_name) AS NationQuantities 
ON 
    tc.nation = NationQuantities.n_name
WHERE 
    NationQuantities.total_quantity > 1000
ORDER BY 
    tc.total_revenue DESC;