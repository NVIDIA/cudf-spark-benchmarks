
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS priority_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F'
), SupplierCost AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100 
    GROUP BY ps.ps_suppkey
), CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
), OrderLineStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    c.c_name,
    cn.nation_name,
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(o.total_line_value, 0) AS total_order_value,
    COALESCE(sc.total_cost, 0) AS supplier_cost,
    r.o_orderpriority AS order_priority
FROM 
    CustomerNation cn
JOIN 
    customer c ON cn.c_custkey = c.c_custkey
LEFT JOIN 
    RankedOrders r ON r.o_orderkey = (
        SELECT o_orderkey 
        FROM RankedOrders 
        WHERE priority_rank = 1 
        LIMIT 1
    )
LEFT JOIN 
    OrderLineStats o ON o.l_orderkey = r.o_orderkey
LEFT JOIN 
    SupplierCost sc ON sc.ps_suppkey = (
        SELECT ps_suppkey 
        FROM partsupp 
        ORDER BY ps_supplycost DESC 
        LIMIT 1
    )
WHERE 
    r.o_orderdate >= DATE '1995-01-01'
AND 
    r.o_orderdate < DATE '1996-01-01'
ORDER BY 
    total_order_value DESC, 
    supplier_cost ASC;
