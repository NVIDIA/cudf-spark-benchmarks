
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM 
        orders o
), 
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_avail,
        ss.avg_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.ps_suppkey
    WHERE 
        ss.avg_supply_cost < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
),
CustomerOrders AS (
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
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    COUNT(DISTINCT lo.l_orderkey) AS lineitem_count,
    MAX(lo.l_extendedprice * (1 - lo.l_discount) * (1 + lo.l_tax)) AS max_order_value,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN co.total_spent > 10000 THEN 'High Spender'
        ELSE 'Regular Spender' 
    END AS customer_type
FROM 
    CustomerOrders co
LEFT JOIN 
    lineitem lo ON co.c_custkey = lo.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON lo.l_suppkey = ts.s_suppkey
WHERE 
    ts.s_name IS NULL OR ts.total_avail > 100
GROUP BY 
    co.c_custkey, co.c_name, co.order_count, co.total_spent
HAVING 
    co.order_count > 0
ORDER BY 
    co.total_spent DESC;
