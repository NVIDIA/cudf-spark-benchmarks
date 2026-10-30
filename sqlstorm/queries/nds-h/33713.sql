
WITH  SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        sd.c_custkey,
        sd.c_name,
        sd.total_sales,
        sd.order_count
    FROM 
        SalesData sd
    WHERE 
        sd.rnk <= 10
)
SELECT 
    tc.c_name,
    COALESCE(p.p_brand, 'Unknown') AS prod_brand,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM 
    TopCustomers tc
LEFT JOIN 
    partsupp ps ON tc.c_custkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    tc.c_name, p.p_brand
HAVING 
    SUM(ps.ps_availqty) > 100
UNION ALL
SELECT 
    'Total' AS c_name,
    NULL AS prod_brand,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM 
    partsupp ps
WHERE 
    ps.ps_availqty IS NOT NULL
ORDER BY 
    total_avail_qty DESC;
