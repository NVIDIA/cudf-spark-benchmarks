WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    COALESCE(ROW_NUMBER() OVER (ORDER BY SUM(l.l_quantity) DESC), 0) AS rank,
    (SELECT AVG(total_spent) FROM CustomerOrderSummary) AS avg_customer_spending,
    SupplierInfo.total_supply_cost
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    SupplierInfo ON ps.ps_suppkey = SupplierInfo.s_suppkey
GROUP BY 
    p.p_name, SupplierInfo.total_supply_cost
HAVING 
    SUM(l.l_quantity) > (SELECT AVG(total_quantity) FROM (SELECT SUM(l_quantity) AS total_quantity FROM lineitem GROUP BY l_partkey) AS subquery)
ORDER BY 
    total_quantity DESC;
