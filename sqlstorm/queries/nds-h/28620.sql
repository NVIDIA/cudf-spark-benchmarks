
WITH SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        CONCAT('Supplier ', s.s_name, ' from ', n.n_name, ' - ', s.s_comment) AS supplier_info
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
        p.p_retailprice,
        p.p_comment,
        CONCAT(p.p_name, ' (', p.p_brand, ') - ', p.p_comment) AS part_info
    FROM
        part p
),
CombinedDetails AS (
    SELECT
        sd.s_name AS supp_name,
        sd.nation,
        pd.part_info,
        COUNT(ps.ps_partkey) AS supply_count,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM
        SupplierDetails sd
    JOIN
        partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN
        PartDetails pd ON ps.ps_partkey = pd.p_partkey
    GROUP BY
        sd.s_name, sd.nation, pd.part_info
)
SELECT
    *,
    CONCAT('Supplier: ', supp_name, ', Nation: ', nation, ', Part Info: ', part_info, 
           ', Supply Count: ', supply_count, ', Total Available Qty: ', total_available_qty) AS benchmark_string
FROM
    CombinedDetails
ORDER BY
    total_available_qty DESC
LIMIT 10;
