WITH TotalRevenue AS (
    SELECT
        n.n_name AS Nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate >= DATE '1994-01-01' AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY
        n.n_name
),
PartSupplier AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name AS Supplier,
        ps.ps_supplycost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        p.p_size > 100 AND ps.ps_availqty < 100
),
HighRevenueRegions AS (
    SELECT
        r.r_name AS Region,
        SUM(tr.Revenue) AS TotalRegionRevenue
    FROM
        TotalRevenue tr
    JOIN
        nation n ON tr.Nation = n.n_name
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY
        r.r_name
    HAVING
        SUM(tr.Revenue) > 1000000
)
SELECT
    hrr.Region,
    ps.p_name,
    ps.Supplier,
    ps.ps_supplycost
FROM
    HighRevenueRegions hrr
JOIN
    PartSupplier ps ON ps.ps_supplycost < 50
ORDER BY
    hrr.TotalRegionRevenue DESC,
    ps.p_name;