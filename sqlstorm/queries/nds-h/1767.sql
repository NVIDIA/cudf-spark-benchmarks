WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
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
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count,
        co.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
SupplierLineItems AS (
    SELECT 
        l.l_orderkey,
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        l.l_orderkey, ps.ps_partkey
)

SELECT 
    hvc.c_custkey,
    hvc.c_name,
    COALESCE(SUM(s.total_supply_cost), 0) AS total_supplier_cost,
    COALESCE(SUM(s.supplier_rank), 0) AS sum_supplier_rank,
    COALESCE(SUM(SL.revenue), 0) AS total_revenue,
    CASE 
        WHEN SUM(SL.revenue) > 0 THEN 'Profitable'
        ELSE 'Non-Profitable'
    END AS profitability_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    RankedSuppliers s ON hvc.order_count > s.supplier_rank
LEFT JOIN 
    SupplierLineItems SL ON hvc.c_custkey = SL.l_orderkey
GROUP BY 
    hvc.c_custkey, hvc.c_name
ORDER BY 
    total_supplier_cost DESC, hvc.c_custkey;
