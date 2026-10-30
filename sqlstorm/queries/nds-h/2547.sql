WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
    AND o.o_orderdate >= '1996-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_retailprice,
        COALESCE(sc.total_cost, 0) AS supply_cost
    FROM part p
    LEFT JOIN SupplierCost sc ON p.p_partkey = sc.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    n.n_name,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
        ELSE 0 
    END) AS returned_sales,
    AVG(CASE 
        WHEN l.l_linestatus = 'F' THEN l.l_extendedprice 
        ELSE NULL 
    END) AS average_fulfilled_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    hp.p_name,
    hp.p_brand,
    hp.supply_cost
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN HighValueParts hp ON l.l_partkey = hp.p_partkey
WHERE l.l_shipdate >= '1996-01-01' 
AND l.l_shipdate < '1997-01-01'
GROUP BY n.n_name, hp.p_name, hp.p_brand, hp.supply_cost
HAVING SUM(l.l_quantity) > 100
ORDER BY returned_sales DESC, average_fulfilled_price DESC
LIMIT 10;