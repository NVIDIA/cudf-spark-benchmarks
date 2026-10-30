WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM
        part p
    WHERE
        p.p_name LIKE '%widget%'
),
SupplierPartDetails AS (
    SELECT
        ps.ps_partkey,
        s.s_name AS supplier_name,
        s.s_address,
        s.s_phone,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE
        ps.ps_availqty > 100
),
PremiumParts AS (
    SELECT
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        sp.supplier_name,
        sp.s_address,
        sp.s_phone,
        sp.ps_supplycost,
        rp.p_retailprice
    FROM
        RankedParts rp
    JOIN
        SupplierPartDetails sp ON rp.p_partkey = sp.ps_partkey
    WHERE
        rp.price_rank <= 5 AND sp.ps_supplycost < rp.p_retailprice
)
SELECT
    pp.p_partkey,
    pp.p_name,
    pp.p_brand,
    pp.supplier_name,
    pp.s_address,
    pp.s_phone,
    pp.ps_supplycost,
    pp.p_retailprice,
    ROUND((pp.p_retailprice - pp.ps_supplycost) / pp.p_retailprice * 100, 2) AS profit_margin_percentage
FROM
    PremiumParts pp
ORDER BY
    pp.p_brand,
    pp.p_retailprice DESC;
