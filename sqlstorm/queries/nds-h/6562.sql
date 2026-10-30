WITH SupplierParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY
        c.c_custkey, c.c_name
),
RegionPerformance AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        SUM(total_available_quantity) AS total_parts_available,
        SUM(total_supply_value) AS total_supply_value,
        SUM(order_count) AS total_orders,
        SUM(total_spent) AS total_spent
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        SupplierParts sp ON s.s_suppkey = sp.s_suppkey
    JOIN
        CustomerOrders co ON co.c_custkey IN (SELECT c.c_custkey FROM customer c
                                                JOIN orders o ON c.c_custkey = o.o_custkey
                                                WHERE o.o_orderdate >= DATE '1997-01-01' 
                                                AND o.o_orderdate < DATE '1997-12-31')
    GROUP BY
        r.r_regionkey, r.r_name
)
SELECT
    r.r_name,
    r.total_parts_available,
    r.total_supply_value,
    r.total_orders,
    r.total_spent,
    CASE 
        WHEN r.total_orders = 0 THEN 0 
        ELSE r.total_spent / r.total_orders 
    END AS avg_order_value
FROM
    RegionPerformance r
ORDER BY
    total_spent DESC;