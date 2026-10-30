WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
), 
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    cs.c_name,
    cs.total_spent,
    sc.total_supply_cost,
    p.p_name,
    COALESCE(l.l_quantity, 0) AS quantity,
    COALESCE(l.l_discount, 0) AS discount,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned' 
        ELSE 'Not Returned' 
    END AS return_status
FROM 
    RankedOrders r
JOIN 
    CustomerSummary cs ON r.o_orderkey = cs.total_orders 
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierCost sc ON l.l_partkey = sc.ps_partkey
JOIN 
    part p ON sc.ps_partkey = p.p_partkey
WHERE 
    r.order_rank <= 5 
    AND cs.total_spent > 10000
ORDER BY 
    r.o_orderkey, cs.total_spent DESC;