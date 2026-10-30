WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ss.total_parts,
        ss.total_supplycost,
        ss.avg_supplycost
    FROM
        SupplierStats ss
    JOIN
        supplier s ON ss.s_suppkey = s.s_suppkey
    ORDER BY
        ss.total_supplycost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    t.s_name AS Supplier_Name,
    t.total_parts AS Total_Parts_Supplied,
    t.total_supplycost AS Total_Supply_Cost,
    t.avg_supplycost AS Average_Supply_Cost,
    co.c_name AS Customer_Name,
    co.total_orders AS Total_Orders,
    co.total_spent AS Total_Spent
FROM
    TopSuppliers t
JOIN
    CustomerOrders co ON t.s_suppkey = co.c_custkey
WHERE
    co.total_spent > 1000
ORDER BY
    t.total_supplycost DESC, co.total_spent DESC;
