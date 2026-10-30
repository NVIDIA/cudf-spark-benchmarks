WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
)
SELECT 
    r.r_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    AVG(l.l_extendedprice - l.l_discount) AS avg_price,
    MAX(l.l_extendedprice) AS max_price,
    SUM(CASE WHEN l.l_returnflag = 'Y' THEN 1 ELSE 0 END) AS total_returns
FROM 
    lineitem l
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
    AND o.o_orderstatus IN (SELECT DISTINCT o_orderstatus FROM RankedOrders WHERE order_rank <= 3)
    AND c.c_custkey IN (SELECT c_custkey FROM TopCustomers)
    AND r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC 
LIMIT 10;