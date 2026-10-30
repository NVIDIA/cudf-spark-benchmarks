
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        o.o_custkey
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_brand,
        p.p_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 0
)
SELECT 
    co.c_name,
    co.total_spent,
    ARRAY_AGG(DISTINCT sp.p_name) AS purchased_parts,
    COUNT(DISTINCT so.o_orderkey) AS distinct_orders,
    COALESCE(SUM(r.l_extendedprice * (1 - r.l_discount)), 0) AS total_revenue,
    AVG(sp.ps_supplycost) AS avg_supply_cost
FROM 
    CustomerOrderSummary co
LEFT JOIN 
    RankedOrders so ON co.c_custkey = so.o_custkey
LEFT JOIN 
    lineitem r ON so.o_orderkey = r.l_orderkey
LEFT JOIN 
    SupplierPartInfo sp ON r.l_partkey = sp.ps_partkey
WHERE 
    co.total_spent > 500.00 
    AND co.c_name LIKE '%Corp%'
GROUP BY 
    co.c_name, co.total_spent
HAVING 
    COUNT(sp.ps_partkey) > 5
ORDER BY 
    avg_supply_cost DESC
LIMIT 
    10;
