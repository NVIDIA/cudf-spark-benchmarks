WITH FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT(p.p_name, ' - ', p.p_brand, ' [', p.p_type, ']') AS part_info
    FROM 
        part p
    WHERE 
        p.p_size > 10 AND 
        p.p_retailprice < 100.00
),
AggregatedData AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(l.l_discount) AS avg_discount,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        FilteredParts fp ON fp.p_partkey = l.l_partkey
    GROUP BY 
        n.n_name
)
SELECT 
    nation_name,
    total_avail_qty,
    avg_discount,
    ROW_NUMBER() OVER (ORDER BY total_avail_qty DESC) AS rank
FROM 
    AggregatedData
WHERE 
    avg_discount > 0.05
ORDER BY 
    rank;
