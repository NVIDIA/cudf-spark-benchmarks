
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(s.total_available_quantity, 0) AS available_qty,
    COALESCE(s.avg_supply_cost, 0) AS avg_supply_cost,
    co.order_count,
    co.total_spent,
    CASE 
        WHEN r.order_rank IS NOT NULL THEN 'Top Order'
        ELSE 'Other Order'
    END AS order_status
FROM 
    part p
LEFT JOIN 
    SupplierParts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    CustomerOrderStats co ON p.p_partkey = co.c_custkey
LEFT JOIN 
    RankedOrders r ON co.order_count > 5 AND r.o_orderkey = co.order_count
WHERE 
    (p.p_retailprice BETWEEN 50.00 AND 100.00 OR p.p_size > 10)
    AND s.avg_supply_cost IS NOT NULL
ORDER BY 
    p.p_retailprice DESC, co.total_spent DESC;
