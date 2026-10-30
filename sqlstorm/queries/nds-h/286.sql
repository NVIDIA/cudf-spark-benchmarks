WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(sp.total_available_qty, 0) AS total_available_qty,
    COALESCE(cp.total_spent, 0) AS total_spent,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(cp.total_spent) OVER () AS avg_customer_spending
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerPurchases cp ON o.o_custkey = cp.c_custkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND (sp.avg_supply_cost > 10 OR p.p_retailprice < 50)
    AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, sp.total_available_qty, cp.total_spent
ORDER BY 
    total_spent DESC, p.p_retailprice ASC;