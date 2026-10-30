
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        r.r_name AS region_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        supplier s ON li.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        li.l_shipdate >= '1997-01-01' 
        AND li.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, r.r_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        region_name,
        c_name,
        total_revenue,
        revenue_rank
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 5
)
SELECT 
    tc.region_name,
    tc.c_name,
    COALESCE(tc.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN tc.total_revenue IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    (SELECT DISTINCT r.r_name FROM region r) r ON tc.region_name = r.r_name
ORDER BY 
    tc.region_name, total_revenue DESC;
