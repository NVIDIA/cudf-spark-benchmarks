WITH NationwideSales AS (
    SELECT
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY
        c.c_nationkey
),
SupplierCost AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        p.p_brand = 'Brand#23'
    GROUP BY
        ps.ps_partkey
),
SalesPerformance AS (
    SELECT
        n.n_name,
        ns.total_sales,
        sc.total_supply_cost,
        ns.total_sales - sc.total_supply_cost AS profit
    FROM
        NationwideSales ns
    JOIN
        nation n ON ns.c_nationkey = n.n_nationkey
    JOIN
        SupplierCost sc ON sc.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0 LIMIT 1)
    ORDER BY
        profit DESC
)
SELECT
    n_name,
    total_sales,
    total_supply_cost,
    profit
FROM
    SalesPerformance
WHERE
    profit > 0
ORDER BY
    total_sales DESC;