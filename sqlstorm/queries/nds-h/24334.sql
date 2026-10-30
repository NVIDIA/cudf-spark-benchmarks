
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_comment, ''), 'No comment') AS safe_comment,
        ARRAY_AGG(DISTINCT ps.ps_partkey) AS available_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_comment
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        SUM(l.l_quantity) OVER (PARTITION BY l.l_orderkey) AS total_quantity,
        MAX(l.l_tax) OVER (PARTITION BY l.l_orderkey) AS max_tax,
        CASE 
            WHEN l.l_returnflag = 'Y' THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status,
        l.l_suppkey
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.1 AND l.l_shipdate IS NOT NULL
)
SELECT 
    p.p_name,
    rd.o_totalprice,
    sd.s_name,
    sd.safe_comment,
    fli.return_status,
    fli.total_quantity,
    fli.max_tax,
    CASE 
        WHEN fli.max_tax IS NULL THEN 'Tax not applicable' 
        ELSE CAST(fli.max_tax AS STRING)
    END AS tax_info
FROM 
    part p
JOIN 
    FilteredLineItems fli ON p.p_partkey = fli.l_partkey
JOIN 
    RankedOrders rd ON fli.l_orderkey = rd.o_orderkey
LEFT JOIN 
    SupplierDetails sd ON fli.l_suppkey = sd.s_suppkey
WHERE 
    rd.price_rank < 10 OR sd.available_parts IS NULL
ORDER BY 
    p.p_name, rd.o_totalprice DESC, sd.s_name;
