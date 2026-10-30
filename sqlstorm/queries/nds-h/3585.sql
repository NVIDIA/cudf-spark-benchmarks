WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerRank AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS cust_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    c.c_name AS customer_name,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_quantity ELSE 0 END) AS total_returns,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    s.total_supply_value,
    cr.total_spent
FROM 
    part p
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerRank cr ON o.o_custkey = cr.c_custkey
LEFT JOIN 
    SupplierStats s ON li.l_suppkey = s.s_suppkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 500.00
    AND (o.o_orderstatus = 'F' OR o.o_orderstatus = 'P')
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, c.c_name, s.total_supply_value, cr.total_spent
HAVING 
    SUM(li.l_quantity) > 0
ORDER BY 
    total_orders DESC,
    total_returns DESC;