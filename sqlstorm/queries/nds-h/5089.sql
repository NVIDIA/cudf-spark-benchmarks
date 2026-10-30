WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
TopBrands AS (
    SELECT 
        rp.p_brand,
        SUM(rp.total_available_qty) AS brand_total_qty
    FROM RankedParts rp
    WHERE rp.rank <= 5
    GROUP BY rp.p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
)
SELECT 
    tb.p_brand,
    tb.brand_total_qty,
    co.total_orders,
    co.total_spent,
    ss.n_name,
    ss.supplier_count,
    ss.total_supply_value
FROM TopBrands tb
JOIN CustomerOrders co ON co.total_orders > 100
JOIN SupplierStats ss ON ss.supplier_count > 10
ORDER BY tb.brand_total_qty DESC, co.total_spent DESC;
