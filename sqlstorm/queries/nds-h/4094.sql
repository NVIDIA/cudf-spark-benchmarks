
WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_custkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierOrderDetails AS (
    SELECT 
        so.o_orderkey,
        so.o_custkey,
        s.s_name,
        sc.total_supply_cost
    FROM
        HighValueOrders so
    LEFT JOIN
        lineitem l ON so.o_orderkey = l.l_orderkey
    LEFT JOIN
        supplier s ON l.l_suppkey = s.s_suppkey
    LEFT JOIN
        SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
)
SELECT 
    sod.o_orderkey,
    sod.o_custkey,
    sod.s_name,
    sod.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY sod.o_custkey ORDER BY sod.total_supply_cost DESC) AS rank,
    CASE 
        WHEN sod.total_supply_cost IS NULL THEN 'No cost available'
        ELSE CAST(sod.total_supply_cost AS STRING)
    END AS formatted_cost
FROM
    SupplierOrderDetails sod
WHERE
    sod.total_supply_cost IS NOT NULL
ORDER BY
    sod.o_orderkey;
