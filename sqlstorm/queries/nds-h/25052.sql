WITH PartSuppliers AS (
    SELECT
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        p.p_retailprice,
        p.p_comment
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
FilteredSuppliers AS (
    SELECT
        p_name,
        supplier_name,
        ps_supplycost,
        ps_availqty,
        p_retailprice,
        p_comment,
        (p_retailprice - ps_supplycost) AS profit_margin 
    FROM
        PartSuppliers
    WHERE
        ps_availqty > 100
)
SELECT
    p_name,
    supplier_name,
    ps_supplycost,
    ps_availqty,
    p_retailprice,
    profit_margin,
    CONCAT('Product: ', p_name, ', offered by ', supplier_name, ', has a profit margin of ', ROUND(profit_margin, 2)) AS profit_message
FROM
    FilteredSuppliers
ORDER BY
    profit_margin DESC;
