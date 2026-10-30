WITH SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment
    FROM
        part p
    WHERE
        p.p_type LIKE '%metal%'
),
OrderLineDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_lines,
        MAX(l.l_shipdate) AS last_ship_date
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey,
        o.o_orderdate
)
SELECT
    sd.s_name,
    pd.p_name,
    od.o_orderkey,
    od.total_revenue,
    od.total_lines,
    od.last_ship_date,
    CONCAT(sd.s_address, ', ', sd.nation) AS supplier_address,
    TRIM(sd.s_comment) AS supplier_comment,
    REPLACE(pd.p_comment, 'excellent', 'outstanding') AS modified_part_comment
FROM
    SupplierDetails sd
JOIN
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN
    OrderLineDetails od ON od.o_orderkey = ps.ps_partkey
WHERE
    sd.s_acctbal > 1000.00
ORDER BY
    od.total_revenue DESC, 
    sd.s_name ASC;
