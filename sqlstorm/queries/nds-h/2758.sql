WITH Supplier_Costs AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
High_Cost_Parts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        sc.total_supply_cost,
        (sc.total_supply_cost / p.p_retailprice) * 100 AS cost_percentage
    FROM
        part p
    JOIN Supplier_Costs sc ON p.p_partkey = sc.ps_partkey
    WHERE
        sc.total_supply_cost > (SELECT AVG(total_supply_cost) FROM Supplier_Costs)
),
Order_Summary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        o.o_orderdate
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
)
SELECT
    hcp.p_partkey,
    hcp.p_name,
    hcp.p_retailprice,
    hcp.total_supply_cost,
    os.total_order_value,
    os.line_count,
    COALESCE(r.r_name, 'Unknown') AS region_name
FROM
    High_Cost_Parts hcp
LEFT JOIN supplier s ON hcp.p_partkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN Order_Summary os ON hcp.p_partkey = os.o_orderkey
WHERE
    hcp.cost_percentage > 75
    AND os.total_order_value IS NOT NULL
ORDER BY
    hcp.total_supply_cost DESC,
    os.line_count DESC;
