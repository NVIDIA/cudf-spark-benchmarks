
WITH  SupplierParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS number_of_parts,
        o.o_orderdate
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
RegionCustomer AS (
    SELECT
        n.n_regionkey,
        c.c_name,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(o.o_totalprice) DESC) AS rnk
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        n.n_regionkey, c.c_name
)
SELECT
    sp.s_name,
    sp.p_name,
    sp.p_brand,
    sp.p_retailprice,
    od.total_revenue,
    od.number_of_parts,
    rc.c_name,
    rc.rnk
FROM
    SupplierParts sp
LEFT JOIN 
    OrderDetails od ON sp.ps_partkey = od.o_orderkey 
FULL OUTER JOIN 
    RegionCustomer rc ON rc.c_name = sp.s_name 
WHERE
    sp.rn <= 5 AND
    (rc.rnk IS NULL OR rc.rnk < 3) 
ORDER BY
    sp.p_brand, od.total_revenue DESC;
