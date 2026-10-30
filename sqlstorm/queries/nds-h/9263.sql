
WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_clerk,
        ts.total_revenue,
        o.o_custkey
    FROM 
        orders o
    JOIN 
        TotalSales ts ON o.o_orderkey = ts.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.o_totalprice) AS total_spent,
        COUNT(od.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_spent,
    cs.order_count,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM 
    CustomerSummary cs
JOIN 
    nation n ON cs.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
ORDER BY 
    cs.total_spent DESC
LIMIT 10;
