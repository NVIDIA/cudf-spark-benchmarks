WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_name AS part_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        pi.part_info AS additional_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        LATERAL (SELECT 
                      CONCAT('Supplier ', s.s_name, ' supplies ', p.p_name, ' and has available quantity of ', ps.ps_availqty) AS part_info
                  ) AS pi ON TRUE
),
RankedSuppliers AS (
    SELECT 
        sd.*, 
        ROW_NUMBER() OVER (PARTITION BY sd.nation_name ORDER BY sd.ps_supplycost DESC) AS rank
    FROM 
        SupplierDetails sd
)
SELECT 
    nation_name,
    part_name,
    s_name,
    ps_availqty,
    ps_supplycost,
    additional_info
FROM 
    RankedSuppliers
WHERE 
    rank <= 10
ORDER BY 
    nation_name, ps_supplycost DESC;
