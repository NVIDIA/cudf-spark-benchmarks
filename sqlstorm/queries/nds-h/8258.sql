WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
TopCustomers AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        r.r_name AS region_name
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rnk <= 5
)
SELECT 
    tc.o_orderkey,
    tc.o_orderdate,
    tc.o_totalprice,
    tc.c_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue,
    AVG(li.l_tax) AS avg_tax,
    COUNT(DISTINCT li.l_orderkey) AS total_lines
FROM 
    TopCustomers tc
JOIN 
    lineitem li ON tc.o_orderkey = li.l_orderkey
GROUP BY 
    tc.o_orderkey, 
    tc.o_orderdate, 
    tc.o_totalprice, 
    tc.c_name
ORDER BY 
    net_revenue DESC
LIMIT 10;