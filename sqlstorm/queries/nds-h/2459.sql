
WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
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
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_stock
    FROM
        part p
    LEFT JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_brand
)
SELECT
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    ps.total_available_qty,
    pd.total_stock,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS rank,
    CASE
        WHEN cs.total_spent > 1000 THEN 'High Value'
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    CustomerOrders cs
JOIN
    SupplierStats ps ON cs.total_spent < ps.avg_supply_cost * 10
JOIN
    PartDetails pd ON pd.total_stock > 0
WHERE
    cs.c_name IS NOT NULL
    AND (pd.p_brand LIKE 'Brand%' OR ps.total_available_qty IS NULL)
ORDER BY
    rank, cs.total_spent DESC
LIMIT 100;
