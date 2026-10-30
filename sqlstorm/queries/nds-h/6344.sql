WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey, c.c_name
),
RegionSummary AS (
    SELECT
        r.r_name,
        SUM(ss.total_cost) AS region_total_cost,
        SUM(co.total_spent) AS region_total_spent
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY
        r.r_name
)
SELECT
    r.r_name,
    r.region_total_cost,
    r.region_total_spent,
    CASE
        WHEN r.region_total_cost IS NOT NULL AND r.region_total_spent IS NOT NULL THEN
            (r.region_total_spent / NULLIF(r.region_total_cost, 0))
        ELSE
            NULL
    END AS cost_to_spent_ratio
FROM
    RegionSummary r
ORDER BY
    r.region_total_cost DESC;
